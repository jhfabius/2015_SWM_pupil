#-*- coding:utf-8 -*-

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

import warnings
from eyelinkparser import EyeLinkParser, sample

class CustomParser(EyeLinkParser):

	def parse_phase(self, l):

		# Only store the sample_stim and wmdelay phases, and downsample the
		# samples to 100 Hz.
		if self.current_phase in ('sample_stim', 'wmdelay') or \
			'sample_stim' in l or 'wmdelay' in l:
			s = sample(l)
			if s is None or s.t % 10 == 0:
				EyeLinkParser.parse_phase(self, l)

	def end_phase(self):

		if len(self.ptrace) > 300:
			warnings.warn('Very long trace, truncating to 300: %s (%d)' \
				% (self.current_phase, len(self.ptrace)))
			self.ptrace = self.ptrace[:300]
			self.xtrace = self.xtrace[:300]
			self.ytrace = self.ytrace[:300]
		EyeLinkParser.end_phase(self)