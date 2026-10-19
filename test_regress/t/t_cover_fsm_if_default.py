#!/usr/bin/env python3
# DESCRIPTION: Verilator: FSM if-chain default transitions
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either the GNU Lesser General Public License Version 3
# or the Perl Artistic License Version 2.0.
# SPDX-FileCopyrightText: 2026 Wilson Snyder
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

import os
import re

import vltest_bootstrap

test.scenarios('vlt')

test.compile(verilator_flags2=['--coverage-fsm', '--coverage-line'])
test.execute()
test.run(cmd=[
    os.environ['VERILATOR_ROOT'] + '/bin/verilator_coverage', '--write',
    test.obj_dir + '/merged.dat', test.coverage_filename
],
         verilator_run=True)

# Compare every FSM state and arc, including zero-hit bins. Sorting removes
# declaration order while retaining duplicate bins and their individual counts.
points = []
with open(test.obj_dir + '/merged.dat', encoding='utf-8') as coverage:
    for line in coverage:
        if '\x02v_fsm_' not in line:
            continue
        point = re.search(r"\x01o\x02([^\x01]+)\x01.*' (\d+)$", line)
        assert point
        points.append(f'{point[1]} {point[2]}\n')

report = test.obj_dir + '/fsm.txt'
with open(report, 'w', encoding='utf-8') as output:
    output.writelines(sorted(points))
test.files_identical(report, test.golden_filename)

test.passes()
