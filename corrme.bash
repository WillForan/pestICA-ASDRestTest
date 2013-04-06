#!/usr/bin/env bash
#
# previously ran pestica.ran.bash and linkinMatAndDat.bash on data

# write corrs.tsv
matlab -nodisplay <<<"getRespCorr"

# remove resp when we dont have it
# that is for all subj mats that have a - in them (held over from labView output format)
cp corrs.tsv corr-bsRM.tsv;
for bs in mat/*-*mat; do 
  b=$(basename $bs .mat);
  b=${b/-*/};
  sed -i "/resp\ts$b/d"  corr-bsRM.tsv;
done

# run R for graph
R --vanilla CMD BATCH plotCorrs.R

