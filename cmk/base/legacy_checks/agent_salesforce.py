#!/usr/bin/env python3
# Copyright (C) 2019 Checkmk GmbH - License: GNU General Public License v2
# This file is part of Checkmk (https://checkmk.com). It is subject to the terms and
# conditions defined in the file COPYING, which is part of this source code package.


from collections.abc import Sequence
from typing import Any, Mapping

from cmk.base.config import special_agent_info


def agent_salesforce_arguments(
    params: Mapping[str, Any], hostname: str, ipaddress: str | None
) -> Sequence[str]:
    args = []
    for instance in params["instances"]:
        args += [
            "--section_url",
            "salesforce_instances,https://api.status.salesforce.com/v1/instances/%s/status"
            % instance,
        ]
    return args


special_agent_info["salesforce"] = agent_salesforce_arguments
