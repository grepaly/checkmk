#!/usr/bin/env python3
# Copyright (C) 2019 Checkmk GmbH - License: GNU General Public License v2
# This file is part of Checkmk (https://checkmk.com). It is subject to the terms and
# conditions defined in the file COPYING, which is part of this source code package.


# mypy: disable-error-code="list-item"

from collections.abc import Sequence
from typing import Any, Mapping

from cmk.base.check_api import passwordstore_get_cmdline
from cmk.base.config import special_agent_info


def agent_emcvnx_arguments(
    params: Mapping[str, Any], hostname: str, ipaddress: str | None
) -> Sequence[str]:
    args: list[str] = []
    if params["user"] != "":
        args += ["-u", params["user"]]
    if params["password"] != "":
        args += ["-p", passwordstore_get_cmdline("%s", params["password"])]
    args += ["-i", ",".join(params["infos"])]

    args.append(ipaddress or hostname)
    return args


special_agent_info["emcvnx"] = agent_emcvnx_arguments
