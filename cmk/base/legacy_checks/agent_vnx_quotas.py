#!/usr/bin/env python3
# Copyright (C) 2019 Checkmk GmbH - License: GNU General Public License v2
# This file is part of Checkmk (https://checkmk.com). It is subject to the terms and
# conditions defined in the file COPYING, which is part of this source code package.


from collections.abc import Sequence
from typing import Any, Mapping

from cmk.base.check_api import passwordstore_get_cmdline
from cmk.base.config import special_agent_info


def agent_vnx_quotas_arguments(
    params: Mapping[str, Any], hostname: str, ipaddress: str | None
) -> Sequence[str | tuple[str, str, str]]:
    args = [
        "-u",
        params["user"],
        "-p",
        passwordstore_get_cmdline("%s", params["password"]),
        "--nas-db",
        params["nas_db"],
    ]
    if "dms_names" in params:
        args += [
            "--dms-names",
            repr(params["dms_names"]),
        ]
    args.append(ipaddress or hostname)
    return args


special_agent_info["vnx_quotas"] = agent_vnx_quotas_arguments
