library(jsonlite)
library(tidyverse)
library(ggthemes)
library(ggpubr)
library(ggpmisc)

history = fromJSON('D:/Masterarbeit/Data/weights/history.json' , flatten=TRUE)
history <- data.frame("loss" = unlist(history$loss), "accuracy" = unlist(history$categorical_accuracy), "val_loss" = unlist(history$val_loss), "val_accuracy" = unlist(history$val_categorical_accuracy) )
history_10 = fromJSON( 'D:/Masterarbeit/Data/weights/history_10.json' )
history_10<- data.frame("loss" = unlist(history_10$loss), "accuracy" = unlist(history_10$categorical_accuracy), "val_loss" = unlist(history_10$val_loss), "val_accuracy" = unlist(history_10$val_categorical_accuracy) )
history_20 = fromJSON( 'D:/Masterarbeit/Data/weights/history_20.json' )
history_20 <- data.frame("loss" = unlist(history_20$loss), "accuracy" = unlist(history_20$categorical_accuracy), "val_loss" = unlist(history_20$val_loss), "val_accuracy" = unlist(history_20$val_categorical_accuracy) )
history_50 = fromJSON( 'D:/Masterarbeit/Data/weights/history_50.json' )
history_50 <- data.frame("loss" = unlist(history_50$loss), "accuracy" = unlist(history_50$categorical_accuracy), "val_loss" = unlist(history_50$val_loss), "val_accuracy" = unlist(history_50$val_categorical_accuracy) )
history_dice = fromJSON( 'D:/Masterarbeit/Data/weights/history_dice.json' )
history_dice <- data.frame("loss" = unlist(history_dice$loss), "binary_accuracy" = unlist(history_dice$binary_accuracy), "val_loss" = unlist(history_dice$val_loss), "val_binary_accuracy" = unlist(history_dice$val_binary_accuracy) )
history_cc = fromJSON( 'D:/Masterarbeit/Data/weights/history_categorical_cross.json' )
history_cc <- data.frame("loss" = unlist(history_cc$loss), "binary_accuracy" = unlist(history_cc$binary_accuracy), "val_loss" = unlist(history_cc$val_loss), "val_binary_accuracy" = unlist(history_cc$val_binary_accuracy) )
history_high_res = fromJSON( 'D:/Masterarbeit/Data/weights/history_high_res_categorical.json' )
history_high_res <- data.frame("loss" = unlist(history_high_res$loss), "categorical_accuracy" = unlist(history_high_res$categorical_accuracy), "val_loss" = unlist(history_high_res$val_loss), "val_categorical_accuracy" = unlist(history_high_res$val_categorical_accuracy) )
history_high_res_dice = fromJSON( 'D:/Masterarbeit/Data/weights/history_high_res_custom_loss.json' )
history_high_res_dice <- data.frame("loss" = unlist(history_high_res_dice$loss), "categorical_accuracy" = unlist(history_high_res_dice$categorical_accuracy), "val_loss" = unlist(history_high_res_dice$val_loss), "val_categorical_accuracy" = unlist(history_high_res_dice$val_categorical_accuracy) )

full_data <- dplyr::bind_rows(list(a_raw = history, b_five = history_50, c_ten = history_10, d_twenty = history_20), .id = 'source')
full_data$epoch <- rep(1:100,4)

full_data <- full_data  %>%
  mutate(source = fct_reorder(source, asc(source)))

check_data <- dplyr::bind_rows(list(categorical_crossentropy = history_cc, dice_loss = history_dice), .id = 'source')
check_data$epoch <- rep(1:100,2)

high_res <- dplyr::bind_rows(list(categorical_crossentropy = history_high_res, dice_loss = history_high_res_dice), .id = 'source')
high_res$epoch <-c(1:100,1:50)

source("D:/Masterarbeit/Data/results/theme_publication.R")
#---------------------------------------------------------------------------------------------
#Plotting Sensitivity analysis history
#---------------------------------------------------------------------------------------------

hist_loss <- ggplot(data=full_data,
                 aes(x=epoch, y=loss, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_line(size = 1.3)+
  ggtitle("Training")+
  ylab("crossentropy loss")+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc <- ggplot(data=full_data,
                    aes(x=epoch, y=accuracy, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_line(size = 1.3)+
  theme_Publication()+
  ylab("categorical accuracy")+
  xlab("epoch")+
  ggtitle("")+
  theme(legend.title = element_blank(), legend.position='none')

hist_loss_val <- ggplot(data=full_data,
                    aes(x=epoch, y=val_loss, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_line(size = 1.3)+
  ggtitle("Testing")+
  ylab("crossentropy loss")+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc_val <- ggplot(data=full_data,
                    aes(x=epoch, y=val_accuracy, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_line(size = 1.3)+
  ylab("categorical accuracy")+
  ylim(min(full_data$val_accuracy), max(full_data$val_accuracy)+0.2)+
  theme_Publication()+
  theme(legend.title = element_blank(),
        legend.justification=c(0,1), legend.position=c(0, max(full_data$val_accuracy)+0.1),
        legend.background = element_blank())+
  xlab("epoch")

four_plots_together <- ggarrange(hist_loss, hist_loss_val,hist_acc, hist_acc_val, ncol = 2, nrow = 2, align = "v", widths = c(1,1,1,1), heights = c(1,1,1.8,1))

ggexport(four_plots_together, filename = "D:/Masterarbeit/Data/results/history_ggplot.pdf", width=15, height=10, res=200)

#---------------------------------------------------------------------------------------------
#Plotting the two other loss functions
#---------------------------------------------------------------------------------------------
hist_loss <- ggplot(data=check_data,
                    aes(x=epoch, y=loss, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ggtitle("Training")+
  ylab("loss")+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc <- ggplot(data=check_data,
                   aes(x=epoch, y=binary_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  theme_Publication()+
  ylab("binary accuracy")+
  xlab("epoch")+
  ggtitle("")+
  theme(legend.title = element_blank(), legend.position='none')

hist_loss_val <- ggplot(data=check_data,
                        aes(x=epoch, y=val_loss, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ggtitle("Testing")+
  ylab("loss")+
  ylim(c(min(check_data$val_loss),1))+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc_val <- ggplot(data=check_data,
                       aes(x=epoch, y=val_binary_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ylab("binary accuracy")+
  xlab("epoch")+
  ylim(min(check_data$val_binary_accuracy), max(check_data$val_binary_accuracy)+0.1)+
  theme_Publication()+
  theme(legend.title = element_blank(), 
        legend.justification=c(0,1), legend.position=c(0, 0.9),
        legend.background = element_blank())

four_plots_together <- ggarrange(hist_loss, hist_loss_val,hist_acc, hist_acc_val, ncol = 2, nrow = 2, align = "v", widths = c(1,1,1,1), heights = c(1,1,1.8,1))

ggexport(four_plots_together, filename = "D:/Masterarbeit/Data/results/history_ggplot_dice.pdf", width=15, height=10, res=200)

#---------------------------------------------------------------------------------------------
#Scatterplot training accuracy vs. testing acuracy and training loss vs. testing loss
#---------------------------------------------------------------------------------------------
lm_dat <- full_data %>% 
  filter(source == "a_raw")

lm <- lm(lm_dat$val_accuracy ~ lm_dat$loss)
summary(lm)

scatter_loss <- ggplot(data=full_data,
                    aes(x=loss, y=val_loss, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label..)), 
               parse = TRUE,
               size = 6) +  
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste( ..rr.label..)),
               label.y = "bottom", label.x = "right",
               parse = TRUE,
               size = 6) +  
  ggtitle("Training loss vs. testing loss")+
  xlab("training \n crossentropy loss")+
  ylab("testing \n crossentropy loss")+
  theme_Publication()+
  theme(legend.title = element_blank(), legend.position='none')

scatter_acc <- ggplot(data=full_data,
                   aes(x=accuracy, y=val_accuracy, colour=source)) +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label..)), 
               parse = TRUE,
               size = 6) +
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste( ..rr.label..)),
               label.y = "bottom", label.x = "right",
               parse = TRUE,
               size = 6) + 
  theme_Publication()+
  xlab("training \n categorical accuracy")+
  ylab("testing \n categorical accuracy")+
  ggtitle("Training accuracy vs. testing accuracy")+
  theme(legend.title = element_blank(), legend.position='none')

scatter_acc_loss <- ggplot(data=full_data,
                        aes(x=loss, y=val_accuracy, colour=source))  +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label..)),
               label.y = "bottom", label.x = "left",
               parse = TRUE,
               size = 6)+
                 stat_poly_eq(formula = y ~ x, 
                              aes(label = paste( ..rr.label..)),
                              label.y = "top", label.x = "right",
                              parse = TRUE,
                              size = 6) + 
  xlab("training \n crossentropy loss")+
  ylab("testing \n categorical accuracy")+
  ggtitle("Training loss vs. testing accuracy")+
  theme_Publication()+
  theme(legend.title = element_blank(),  legend.position='none')

scatter_leg <- ggplot(data=full_data,
                           aes(x=loss, y=val_accuracy, colour=source))  +
  scale_color_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_point(size = 1)+
  theme_Publication()+
  theme(legend.title = element_blank(),
        legend.direction = "vertical",
        legend.key.size= unit(1, "cm"),
        legend.key.width= unit(1, "cm"))+ guides(colour = guide_legend(override.aes = list(size = 6)))

# Extract the legend. Returns a gtable
leg <- get_legend(scatter_leg)
leg <- as_ggplot(leg)

four_plots_together <- ggarrange(scatter_loss,scatter_acc,scatter_acc_loss, leg, ncol = 2, nrow = 2, align = "v", widths = c(1,1,1,1), heights = c(1,1,1.8,1))

ggexport(four_plots_together, filename = "D:/Masterarbeit/Data/results/scatter.pdf", width=15, height=10, res=200)

#---------------------------------------------------------------------------------------------
# Boxplot
#---------------------------------------------------------------------------------------------

long_loss <- 
  full_data %>% 
  gather("loss", "val_loss",key = split, value = loss) %>% 
  mutate(split = factor(split, labels = c("training loss", "testing loss"))) %>% 
  mutate(source = factor(source, labels = c("raw data", "+5%", "+10%","+20%")))

box_loss <- ggplot(long_loss, aes(x=factor(source), y = loss, fill=source)) +
  scale_fill_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_boxplot()+
  facet_wrap(~split,ncol = 2,labeller=label_value) +
  theme_Publication()+
  ylab("crossentropy loss")+
  ggtitle("boxplots loss")+
  theme(legend.title = element_blank(), legend.position='none', axis.title.x = element_blank())


long_acc <- 
full_data %>% 
  gather("accuracy", "val_accuracy",key = split, value = accuracy) %>% 
  mutate(split = factor(split, labels = c("training accuracy", "testing accuracy"))) %>% 
  mutate(source = factor(source, labels = c("raw data", "+5%", "+10%","+20%")))

box_acc <- ggplot(long_acc, aes(x=factor(source), y = accuracy, fill=source)) +
  scale_fill_manual(labels = c("raw data", "+5%", "+10%","+20%"),values=c("#999999", "#E69F00", "#56B4E9", "indianred"))+
  geom_boxplot()+
  facet_wrap(~split,ncol = 2,labeller=label_value) +
  theme_Publication()+
  ylab("categorical accuracy")+
  ggtitle("boxplots accuracy")+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.direction = "horizontal", legend.position = "bottom")



two_plots_together <- ggarrange(box_loss,box_acc,  ncol = 1, nrow = 2, align = "v", widths = c(1,1), heights = c(1,1.2))

ggexport(two_plots_together, filename = "D:/Masterarbeit/Data/results/box.pdf", width=11, height=9, res=200)

#---------------------------------------------------------------------------------------------
#Scatterplot dice and binary_crossentropy
#---------------------------------------------------------------------------------------------

scatter_loss <- ggplot(data=check_data,
                       aes(x=val_loss, y=loss, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label.., ..rr.label.., sep = "~~~")), 
               parse = TRUE,
               size = 6) + 
  ggtitle("Training loss vs. testing loss")+
  ylab("trainingloss")+
  xlab("testing loss")+
  xlim(c(0,1.5))+
  theme_Publication()+
  theme(legend.title = element_blank(), legend.position='none')

scatter_acc <- ggplot(data=check_data,
                      aes(x=val_binary_accuracy, y=binary_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label.., ..rr.label.., sep = "~~~")), 
               parse = TRUE,
               size = 6) + 
  theme_Publication()+
  ylab("training \n binary accuracy")+
  xlab("testing \n binary accuracy")+
  ggtitle("Training accuracy vs. testing accuracy")+
  theme(legend.title = element_blank(), legend.position='none')

scatter_acc_loss <- ggplot(data=check_data,
                           aes(x=loss, y=val_binary_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_point(size = 1.3)+
  geom_smooth(method = "lm", fill = NA)+
  stat_poly_eq(formula = y ~ x, 
               aes(label = paste(..eq.label.., ..rr.label.., sep = "~~~")),
               label.y = "bottom", label.x = "left", 
               parse = TRUE,
               size = 6) + 
  ylab("training \n binary accuracy")+
  xlab("training loss")+
  ggtitle("Training loss vs. testing accuracy")+
  theme_Publication()+
  theme(legend.title = element_blank(),  legend.position='none')

scatter_leg <- ggplot(data=check_data,
                      aes(x=loss, y=val_binary_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_point(size = 2)+
  theme_Publication()+
  theme(legend.title = element_blank(),
        legend.direction = "vertical",
        legend.key.size= unit(1, "cm"),
        legend.key.width= unit(1, "cm"))+ guides(colour = guide_legend(override.aes = list(size = 6)))

# Extract the legend. Returns a gtable
leg <- get_legend(scatter_leg)
leg <- as_ggplot(leg)

three_plots_together <- ggarrange(scatter_loss,scatter_acc,scatter_acc_loss, leg, ncol = 2, nrow = 2, align = "v", widths = c(1,1,1,1), heights = c(1,1,1.8,1))

ggexport(three_plots_together, filename = "D:/Masterarbeit/Data/results/scatter_bin.pdf", width=15, height=10, res=200)

#---------------------------------------------------------------------------------------------
#Find best val acc and so on
#---------------------------------------------------------------------------------------------

best_data_val_acc <- 
  full_data %>% 
  group_by(source) %>% 
  filter(val_accuracy == max(val_accuracy)) %>%
  ungroup()

best_data_acc <- 
  full_data %>% 
  group_by(source) %>% 
  filter(accuracy == max(accuracy)) %>%
  ungroup()

best_data_loss <- 
  full_data %>% 
  group_by(source) %>% 
  filter(loss == min(loss)) %>%
  ungroup()

write.csv(best_data_val_acc,"D:/Masterarbeit/Data/results/sbest_val_acc.csv", row.names = FALSE, quote = FALSE)
write.csv(best_data_acc,"D:/Masterarbeit/Data/results/sbest_acc.csv", row.names = FALSE, quote = FALSE)
write.csv(best_data_loss,"D:/Masterarbeit/Data/results/sbest_loss.csv", row.names = FALSE, quote = FALSE)

best_data_acc_high_res <- 
  high_res %>% 
  group_by(source) %>% 
  filter(categorical_accuracy == max(categorical_accuracy)) %>%
  ungroup()

best_data_loss_high_res <- 
  high_res %>% 
  group_by(source) %>% 
  filter(loss == min(loss)) %>%
  ungroup()

#---------------------------------------------------------------------------------------------
#HIGH RESOLUTION
#---------------------------------------------------------------------------------------------

hist_loss <- ggplot(data=high_res,
                    aes(x=epoch, y=loss, colour=source)) +
  scale_color_manual(labels = c("categorical crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ggtitle("Training")+
  ylab("loss")+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc <- ggplot(data=high_res,
                   aes(x=epoch, y=categorical_accuracy, colour=source)) +
  scale_color_manual(labels = c("categorical crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  theme_Publication()+
  ylab("binary accuracy")+
  xlab("epoch")+
  ggtitle("")+
  theme(legend.title = element_blank(), legend.position='none')

hist_loss_val <- ggplot(data=high_res,
                        aes(x=epoch, y=val_loss, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ggtitle("Testing")+
  ylab("loss")+
  ylim(c(min(high_res$val_loss),1))+
  theme_Publication()+
  theme(legend.title = element_blank(), axis.title.x = element_blank(), legend.position='none')

hist_acc_val <- ggplot(data=high_res,
                       aes(x=epoch, y=val_categorical_accuracy, colour=source)) +
  scale_color_manual(labels = c("binary crossentropy", "dice loss"),values=c("#51873E", "#3E4587"))+
  geom_line(size = 1.3)+
  ylab("binary accuracy")+
  xlab("epoch")+
  ylim(min(high_res$val_categorical_accuracy), max(high_res$val_categorical_accuracy)+0.2)+
  theme_Publication()+
  theme(legend.title = element_blank(), 
        legend.justification=c(0,1), legend.position=c(0, 0.9),
        legend.background = element_blank())

four_plots_together <- ggarrange(hist_loss, hist_loss_val,hist_acc, hist_acc_val, ncol = 2, nrow = 2, align = "v", widths = c(1,1,1,1), heights = c(1,1,1.8,1))

ggexport(four_plots_together, filename = "D:/Masterarbeit/Data/results/history_ggplot_high_res.pdf", width=15, height=10, res=200)

