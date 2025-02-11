# Load necessary libraries
library(tidyverse)  # For data manipulation and visualization
library(shadowtext) # For enhanced text visualization
library(patchwork)  # For arranging multiple plots
library(grid)       # For additional grid graphics

# Create fake data, replace this with however you choose to load your data
df <- data.frame(
  'Funnel.Stage' = c(
    "B - Application Review",
    "D - Recruiter Screen",
    "E - Hiring Manager Screen",
    "F - Skills/Take Home Test",
    "G - Onsite Interview",
    "K - Offer Accepted"
  ),
  'Total.Applications.in.Funnel' = c(
    1500,
    150,
    75,
    27,
    9,
    8
  )
)

# Filter and process the data for specific analyses -- this will likely change based on your data
df <- df %>%
  filter(
    Funnel.Stage %in% c("D - Recruiter Screen", 
                                  "E - Hiring Manager Screen", 
                                  "F - Skills/Take Home Test", 
                                  "G - Onsite Interview", 
                                  "K - Offer Accepted")
  ) %>% 
  # Clean and reformat the funnel stage names
  mutate(
    Funnel.Stage = sub("^[A-Z] - ", "", Funnel.Stage)
  ) %>%
  # Calculate passthrough rate and define factor levels
  mutate(
    Passthrough_Rate = Total.Applications.in.Funnel / lag(Total.Applications.in.Funnel),
    Funnel.Stage = factor(Funnel.Stage, levels = rev(Funnel.Stage))
  )

# Convert passthrough rate to percentage for easier readability
df <- df %>%
  mutate(Passthrough_Rate_Percent = scales::percent(Passthrough_Rate, accuracy = 1))

# Reorder the factor levels based on the total number of applications
df$Funnel.Stage <- fct_reorder(df$Funnel.Stage, df$Total.Applications.in.Funnel)


# Plot 1: Passthrough rates visualized as points along a vertical line
p1 <- ggplot(df, aes(x = 1, y = Funnel.Stage)) +
  # Add a vertical line for context
  annotate("segment", x = 1, 
           xend = 1, 
           yend = "Recruiter Screen", 
           y = "Offer Accepted", 
           color = "lightgrey", 
           size = 2) +
  # Plot points representing each stage
  geom_point(aes(fill = `Total.Applications.in.Funnel`),
             shape = 21, 
             size = 25,
             color = "transparent") +
  # Gradient for point fill
  scale_fill_gradient(low = "#AAD1B4", high = "#00751D") +
  # Add text labels with passthrough percentages
  geom_text(aes(label = Passthrough_Rate_Percent), 
            color = "white",
            size = 5.5, 
            family="Poppins",
            fontface="bold") +
  # Theme adjustments for a minimal look
  theme_void() +
  theme(
    plot.margin = unit(c(0, 0, 0, 0), "cm"),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    # Remove Legend
    legend.position = "none"
  ) +
  labs(x = NULL, y = NULL) +
  expand_limits(x = c(0.5, 1.5))
p1

# Plot 2: Funnel stages with bar heights illustrating total applications
p2 <- ggplot(df, aes(x = Funnel.Stage, y = Total.Applications.in.Funnel, group = 1)) +
  # Area plot for continuity in bar heights
  geom_area(fill = "gray", alpha = 0.2) +
  # Bar plot for precise total application counts
  geom_col(aes(fill = Total.Applications.in.Funnel), width = 0.8) +
  # Color scale for bars
  scale_fill_gradient(high = "#00751D", low = "#AAD1B4") +
  # Annotate with text below each bar
  geom_text(
    data = subset(df, Total.Applications.in.Funnel < 150),
    aes(Funnel.Stage, 
        y = 0, 
        label = paste0(Funnel.Stage, "\n", "Applicants: ",  scales::comma(Total.Applications.in.Funnel))),
    hjust = 0,
    nudge_y = 1,
    colour = "black",
    family = "Poppins",
    size = 5,
    fontface="bold"
  ) + 
  geom_text(
    data = subset(df, Total.Applications.in.Funnel >= 150),
    aes(Funnel.Stage, 
        y = 0, 
        label = paste0(Funnel.Stage, "\nApplicants: ", scales::comma(Total.Applications.in.Funnel))),
    hjust = 0,
    nudge_y = 1,
    colour = "white",
    family = "Poppins",
    size = 5,
    fontface="bold"
  ) +
  # Theme styling for bar graph aesthetics
  theme(
    plot.margin = unit(c(0, 0, 0, 0), "cm"),
    # Set background color to white
    panel.background = element_rect(fill = "white"),
    # Remove tick marks by setting their length to 0
    axis.ticks.length = unit(0, "mm"),
    # Remove the title for both axes
    axis.title = element_blank(),
    # But customize labels for the horizontal axis
    axis.text = element_text(family = "Poppins",
                             size = 9,
                             face="bold"),
    # Remove labels from the vertical and horizontal axis
    axis.text.y = element_blank(),
    axis.text.x = element_blank(),
    # Remove Legend
    legend.position = "none",
    # Edit Title defaults
    plot.title = element_text(
      family = "Poppins",
      face = "bold",
      size = 18
    ),
    plot.subtitle = element_text(
      family = "Poppins",
      size = 10,
      color = "#808080"
    ),
    plot.caption = element_text(
      family = "Poppins",
      size = 8,
      color = "#808080",
      hjust=0
    )
  ) +
  scale_y_continuous(limits = c(0, 1.02*max(df$Total.Applications.in.Funnel)), expand = c(0, 0), position = "right") +
  coord_flip()

p2

# Layout design for combining plots
layout <- "
ABBBBBBBBB
ABBBBBBBBB
ABBBBBBBBB
"
# Combine plots p1 and p2 using the specified layout
patch <- p1 + p2 + plot_layout(design = layout) 
# Add title and captions to the composite plot
patch_w_title <- patch + 
  plot_annotation(
    title = "Passthrough Rates",
    subtitle = "Fake Data Source",
    caption = "Design: Carlos Rodriguez-Munoz",
    theme = theme(
      plot.title = element_text(family = "Poppins",
                                size = 22,
                                face="bold"),
      plot.subtitle = element_text(family = "Poppins",
                                   size = 10,
                                   color = "#808080",
                                   face="bold"),
      plot.caption = element_text(family = "Poppins",
                                  color = "#808080",
                                  size = 9,
                                  hjust = 0)
      
    )
  )

patch_w_title

# Save the composite plot as a PNG image
ggsave("PassthroughRates.png",
       #path = "~/Downloads",
       plot = patch_w_title,
       width = 900*300/72,
       height = 550*300/72,
       units = "px",
       dpi="print")
