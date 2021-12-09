// Copyright (C) 2019 tribe29 GmbH - License: GNU General Public License v2
// This file is part of Checkmk (https://checkmk.com). It is subject to the terms and
// conditions defined in the file COPYING, which is part of this source code package.

use super::cli;
use anyhow::{Context, Result as AnyhowResult};
use serde::de::DeserializeOwned;
use serde::Deserialize;
use serde::Serialize;
use std::collections::HashMap;
use std::fs::{read_to_string, write};
use std::io;
use std::path::Path;

pub trait JSONLoader: DeserializeOwned {
    fn new() -> AnyhowResult<Self> {
        Ok(serde_json::from_str("{}")?)
    }

    fn load(path: &Path) -> AnyhowResult<Self> {
        if !path.exists() {
            return Self::new();
        }
        Ok(serde_json::from_str(&read_to_string(path)?)?)
    }
}

pub type AgentLabels = HashMap<String, String>;

#[derive(Deserialize)]
pub struct Credentials {
    pub username: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct ConfigFromDisk {
    #[serde(default)]
    pub agent_receiver_address: Option<String>,

    #[serde(default)]
    pub credentials: Option<Credentials>,

    #[serde(default)]
    pub root_certificate: Option<String>,

    #[serde(default)]
    pub host_name: Option<String>,

    #[serde(default)]
    pub agent_labels: Option<AgentLabels>,
}

impl JSONLoader for ConfigFromDisk {}

pub enum HostRegistrationData {
    Name(String),
    Labels(AgentLabels),
}

pub struct RegistrationConfig {
    pub agent_receiver_address: String,
    pub credentials: Credentials,
    pub root_certificate: Option<String>,
    pub host_reg_data: HostRegistrationData,
}

impl RegistrationConfig {
    pub fn new(
        config_from_disk: ConfigFromDisk,
        reg_args: cli::RegistrationArgs,
    ) -> AnyhowResult<RegistrationConfig> {
        let agent_receiver_address = reg_args
            .server
            .or(config_from_disk.agent_receiver_address)
            .context("Missing server address")?;
        let credentials =
            if let (Some(username), Some(password)) = (reg_args.user, reg_args.password) {
                Credentials { username, password }
            } else {
                config_from_disk
                    .credentials
                    .context("Missing credentials")?
            };
        let root_certificate = config_from_disk.root_certificate;
        let stored_host_name = config_from_disk.host_name;
        let stored_agent_labels = config_from_disk.agent_labels;
        let host_reg_data = reg_args
            .host_name
            .map(HostRegistrationData::Name)
            .or_else(|| stored_host_name.map(HostRegistrationData::Name))
            .or_else(|| stored_agent_labels.map(HostRegistrationData::Labels))
            .context("Neither hostname nor agent labels found")?;
        Ok(RegistrationConfig {
            agent_receiver_address,
            credentials,
            root_certificate,
            host_reg_data,
        })
    }
}

#[derive(Serialize, Deserialize)]
pub struct RegisteredConnection {
    #[serde(default)]
    pub uuid: String,

    #[serde(default)]
    pub private_key: String,

    #[serde(default)]
    pub certificate: String,

    #[serde(default)]
    pub root_cert: String,
}

#[derive(Serialize, Deserialize)]
pub struct RegisteredConnections {
    #[serde(default)]
    pub push: HashMap<String, RegisteredConnection>,

    #[serde(default)]
    pub pull: HashMap<String, RegisteredConnection>,

    #[serde(default)]
    pub pull_imported: Vec<RegisteredConnection>,
}

impl JSONLoader for RegisteredConnections {}

impl RegisteredConnections {
    pub fn to_file(&self, path: &Path) -> io::Result<()> {
        write(path, &serde_json::to_string_pretty(self)?)
    }

    pub fn is_empty(&self) -> bool {
        self.push.is_empty() & self.pull.is_empty() & self.pull_imported.is_empty()
    }

    pub fn register_push_host(&mut self, server: String, conn: RegisteredConnection) {
        self.pull.remove(&server);
        self.push.insert(server, conn);
    }

    pub fn register_pull_host(&mut self, server: String, conn: RegisteredConnection) {
        self.push.remove(&server);
        self.pull.insert(server, conn);
    }
}
