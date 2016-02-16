
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from datamatrix import plot as dmplot
from datamatrix import series
from datamatrix.colors.tango import *
from matplotlib import pyplot as plt
import eyelinkparser

# Use the eyelinkparser to get the data. For this basic analyis, we don't need
# a custom parser class yet.
dm = eyelinkparser.parse(cacheid='data')

# Take the pupil trace during wmdelay, and turn it into a blink-reconstructed
# trace of 3000 ms that is normalized relative to the first 100 ms of the
# sample_stim trace.
dm.pupil = dm.ptrace_wmdelay
dm.pupil = series.blinkreconstruct(dm.pupil)
dm.pupil.depth = 3000
dm.pupil = series.baseline(dm.pupil, dm.ptrace_sample_stim, 0, 100)
# Create a new plot, and plot both conditions as separate subplots.
dmplot.new()
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
	plt.legend(loc='lower left')
dmplot.save('pupil')