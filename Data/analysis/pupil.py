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

import os
from datamatrix.rbridge import lme4
from datamatrix import plot as dmplot
from datamatrix import series, cached
from datamatrix import operations as ops
from datamatrix.colors.tango import *
from matplotlib import pyplot as plt


@cached
def preprocess(dm):

	# Participant BB had three unfinished blocks, which need to be removed.
	# These have also been removed from the repository.
	dm = dm.path != 'data/BB_O03.asc'
	dm = dm.path != 'data/BB_O04.asc'
	dm = dm.path != 'data/BB_O09.asc'
	# Summarize and get only valid trials
	print('N(total) = %d' % len(dm))
	dm = dm.valid == 1
	print('N(valid) = %d' % len(dm))
	# Check whether all blocks contain exactly 16 valid trials
	for path, dm_ in ops.split(dm.path):
		assert(len(dm_) == 16)
	# Check whether we have exacty two conditions and backgroundcolors
	assert(len(dm.condition.unique) == 2)
	assert(len(dm.backgroundcolor.unique) == 2)
	# Extract subject ids from the first two letters of the source-asc basename
	dm.sid = -1
	for row in dm:
		row.sid = os.path.basename(row.path)[:2]
	# Take the pupil trace during wmdelay, and turn it into a blink-reconstructed
	# trace of 3000 ms that is normalized relative to the first 100 ms of the
	# sample_stim trace.
	dm.pupil = dm.ptrace_wmdelay
	print('wmdelay = %d' % dm.ptrace_wmdelay.depth)
	print('sample_stim = %d' % dm.ptrace_sample_stim.depth)
	dm.pupil = series.blinkreconstruct(dm.pupil)
	dm.pupil.depth = 300
	dm.pupil = series.baseline(dm.pupil, dm.ptrace_sample_stim, 0, 10)
	return dm


def pupil_plot(dm, suffix=''):

	# Create a new plot, and plot both conditions as separate subplots.
	for i, condition in enumerate(['L', 'O']):
		plt.subplot(2,1,i+1)
		plt.title('Condition %s' % condition)
		dm_dark = (dm.condition == condition) & (dm.backgroundcolor == 0)
		dm_bright = (dm.condition == condition) & (dm.backgroundcolor == 255)
		dmplot.trace(dm_dark.pupil, color=blue[1],
			label='Attend dark (N=%d)' % len(dm_dark))
		dmplot.trace(dm_bright.pupil, color=orange[1],
			label='Attend bright (N=%d)' % len(dm_bright))
		plt.xlabel('Time in retention interval (ms)')
		plt.ylabel('Pupil size (norm.)')
		plt.legend(loc='upper left')
	dmplot.save('pupil'+suffix)


def subject_plot(dm):

	for sid, dm_ in ops.split(dm.sid):
		pupil_plot(dm_, 'pupil-%s' % sid)


def stats_plot(dm):

	model = 'pupil ~ condition * backgroundcolor + (1+condition*backgroundcolor|sid)'
	lm = lme4.lmer_series(dm, model, winlen=10, cacheid='lmer')
	for i in range(1, 4):
		plt.plot(lm.t[i], label=lm.effect[i])
	plt.axhline(0, linestyle=':', color='black')
	plt.axhline(-2, linestyle=':', color='black')
	plt.axhline(2, linestyle=':', color='black')
	plt.legend()
	dmplot.save('t-values')


def descriptives(dm):

	print('N(subject) = %d' % len(dm.sid.unique))
	print('N(trial) = %d' % len(dm))
	for sid, dm_ in ops.split(dm.sid):
		print('%s: %d trials, accuracy = %.2f' \
			% (sid, len(dm_), dm_.response.mean))
