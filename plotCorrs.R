library(ggplot2)
d <- read.table('corr-bsRM.tsv',header=F,sep="\t")
names(d)<-c('measure','subj','time','R')

d$time <- factor(d$time, levels=c('init','trunc','phase') )

ggplot(d,aes(x=time,y=R,color=subj))+geom_point()+geom_line(aes(group=subj))+facet_wrap(~measure)
ggsave('corrs.png')

