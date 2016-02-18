#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
This file is part of SWM_PUPIL.

SWM_PUPIL is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SWM_PUPIL is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with SWM_PUPIL.  If not, see <http://www.gnu.org/licenses/>.
"""

import eyelinkparser
from datamatrix import dispatch
from analysis import pupil, parse

# The waterfall resumes the analysis from the last point on that was not cached.
dm = dispatch.waterfall(
	(eyelinkparser.parse, 'data', {'parser' : parse.CustomParser}),
	(pupil.preprocess, 'preprocess', {})
	)
# The dispatch automatically calls functions that have been specified on the
# command line, like so: ./analyze.py @pupilplot @subject_plot
dispatch.dispatch(dm, pupil)
