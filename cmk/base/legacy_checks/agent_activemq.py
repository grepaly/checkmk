#!/usr/bin/env python3
# Copyright (C) 2019 Checkmk GmbH - License: GNU General Public License v2
# This file is part of Checkmk (https://checkmk.com). It is subject to the terms and
# conditions defined in the file COPYING, which is part of this source code package.


from collections.abc import Sequence
from typing import Any, Mapping

from cmk.base.check_api import passwordstore_get_cmdline
from cmk.base.config import special_agent_info


def agent_activemq_arguments(
    params: Mapping[str, Any], hostname: str, ipaddress: str | None
) -> Sequence[str]:
    return (
        [
            params["servername"],
            f"{params['port']}",
            "--protocol",
            params["protocol"],
        ]
        + (["--piggyback"] if params.get("use_piggyback") else [])
        + (
            [
                "--username",
                params["basicauth"][0],
                "--password",
                passwordstore_get_cmdline("%s", params["basicauth"][1]),
            ]
            if "basicauth" in params
            else []
        )
    )


special_agent_info["activemq"] = agent_activemq_arguments
