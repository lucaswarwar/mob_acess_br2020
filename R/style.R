library(tidyverse)
library(ggtext)

aop_style <- function() {
  font <- "Helvetica"
  
  ggplot2::theme(
    
    text = element_text(family = font, colour = "#808080", size = 14),
    
    # Titles
    # Font, size, type, colour, lineheight, margin, for the chart's title, subtitle, caption
    plot.title = ggtext::element_markdown(
      lineheight = 1.5, family = font, size = 20),
    plot.subtitle = ggtext::element_markdown(
      lineheight = 1.5, colour = "#808080", family = font, size = 16
    ),
    plot.title.position = "plot",
    plot.caption = ggtext::element_markdown(
      margin = margin(t = 10), size = 12, hjust = 0, colour = "#808080"),
    plot.caption.position = "plot",
    
    # Legend
    # Legend is set to be excluded. However, in case it is needed, the code below sets its configuration. May need aditional manual tweaking
    legend.position = "none",
    legend.background = ggplot2::element_blank(),
    legend.title = ggtext::element_markdown(size = 16, colour = "#808080"),
    legend.text = ggtext::element_markdown(size = 14, colour = "#808080"),
    legend.key = element_blank(),
    
    # Axis
    # Formats axis text, ticks, line and titles. Axis titles are formated, but can be excluded with axis.title.x or y = element_blank()
    axis.text = element_markdown(size = 14, colour = '#808080'),
    axis.ticks = element_blank(),
    axis.line.x = element_line(size = 0.5, color = "grey"),
    axis.line.y = element_blank(),
    axis.title.y = element_blank(),
    axis.title.x = element_blank(),
    # if axis.title is needed, use the following format. Adjust vjust, angle, margin accordingly
    # axis.title = element_markdown(size = 16, colour = '#808080')
    
    # Panel
    # Format panel grid, border, spacing, background. Aditional manual tweking may be necessary
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    panel.spacing.x = unit(1.5, "lines"),
    plot.background = ggplot2::element_rect(fill = NA),
    panel.background = ggplot2::element_rect(fill = NA),
    
    # Strip
    # Format strips
    strip.placement = "outside",
    strip.background = ggplot2::element_rect(fill = NA),
    strip.text = element_text(size = 14, face = "plain", colour = "#808080"),
    
    # Margin
    # Format plot.margin. Adjust if necessary
    plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm")
    
  )
}