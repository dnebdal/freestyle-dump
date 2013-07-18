# Copyright Daniel Nebdal <daniel@nebdal.net> 2013. 
# https://github.com/dnebdal/freestyle-dump/
# Distributed under the 2-clause BSD license, ref. LICENSE.

library(ggplot2)
library(scales)

read.dumpfile = function(filename) {
  # Read fixed-width file:
  data = read.fwf(filename, 
    widths = c(3,1,19,7), skip=6, sep="!", header=F, 
    col.names=c("glucose", "na", "date", "na2"),
    strip.white=T, stringsAsFactors=F
  )

  # Strip uninteresting columns and last line (END)
  data = data[,c(1,3)]
  data = data[-nrow(data), ]

  device = scan(filename, c(""), nlines=1)
  data$deviceID = rep(device, nrow(data))
  return(data)
}

tables = lapply(Sys.glob("freestyle-*.txt"), read.dumpfile)
data = Reduce(rbind, tables)
data$deviceID = as.factor(data$deviceID)

# Parse dates.
# Month names are locale sensitive, and shortnames really weird.
data$date = gsub("  ", " ", data$date)
months = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
for (num in 1:12) {
  data$date = sub(months[num], sprintf("%02i",num), data$date)
}
data$posixtime = as.POSIXct(data$date, "CET", format="%m %d %Y %H:%M")
data$date = format(data$posixtime, "%Y-%m-%d")
data$time = format(data$posixtime,  "%H:%M")

# Sort, newest at the end
data = data[order(data$posixtime), ]

# Convert to mmol/l. Change HI to 27 mmol/l
data$glucose = sub("HI", 487, data$glucose)
data$glucose = as.numeric(data$glucose)
data$glucose = data$glucose * 0.0555

# downweigh repeats
data$weight = rep(1, nrow(data))
for (row in 2:nrow(data)) {
  diff = data[row, "posixtime"] - data[row-1, "posixtime"]
  if (diff >= 3) next
  data$weight[row] = diff/3
}

#plot
data$posix.timeonly = as.POSIXct(data$time, format="%H:%M")
data$date = as.factor(data$date)

# The geom_rect defines its own set of data, then plots a single box based on it.
# It still needs posix.timeonly, just to stop ggplot from complaining.

ggplot(data, aes(posix.timeonly, glucose))  + 
geom_rect(
  fill="darkgreen", alpha=0.5, 
  data=data.frame(
    x1=as.POSIXct("00:00", format="%H:%M"), 
    x2=as.POSIXct("23:59:59", format="%H:%M:%s"), 
    y1=4.5, 
    y2=8,
    posix.timeonly=as.POSIXct("00:00", format="%H:%M"), 
    glucose=0
  ), 
  aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2)
) +
geom_point(aes(size=weight, color=deviceID)) + 
geom_smooth(se=F, size=1.5, span=3/24, aes(weight = weight, color=deviceID)) + 
geom_smooth(se=F, size=2, span=3/24, aes(weight = weight)) + 
scale_size(range=c(0, 4)) +
scale_x_datetime(breaks = date_breaks("1 hour"), labels=date_format("%H:%M"), expand=c(0,0)) +
scale_y_continuous(breaks= 2*(1:14) )



