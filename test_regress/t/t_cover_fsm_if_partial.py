#!/usr/bin/env python3
# DESCRIPTION: Verilator: FSM defaults must respect preceding state branches
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either the GNU Lesser General Public License Version 3
# or the Perl Artistic License Version 2.0.
# SPDX-FileCopyrightText: 2026 Hudson River Trading LLC
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

import os

import vltest_bootstrap

test.scenarios('vlt')

test.compile(verilator_flags2=['--coverage-fsm', '--coverage-line'])
test.execute()
test.run(cmd=[
    os.environ['VERILATOR_ROOT'] + '/bin/verilator_coverage', '--write',
    test.obj_dir + '/merged.dat', test.coverage_filename
],
         verilator_run=True)

# Rejecting the unsupported chain is valid; inventing an unreachable arc is not.
test.file_grep_not(test.obj_dir + '/merged.dat', r'v_fsm_arc/.*state::IDLE->RUN')

test.passes()
