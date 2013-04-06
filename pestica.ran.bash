#!/usr/bin/env bash

#
# run pestica on everyone!
#  - set up names
#  - motion correct
#  - pestica
# output: 
# 
MAXJOBS=5
source $(dirname $0)/setup_pestica_AutFace.sh

# start fake xserver for afni on display 9
#xvfb :9 &
#xserverpid=$!

function runpestica {
   restdir=$1
   cd $restdir

   date +%F+%H:%M:%S > pestica.incomplete
   echo
   cat pestica.incomplete
   echo

   input=rest.nii.gz
   subj=$(basename $(dirname $restdir))

   [ ! -r $input ] && echo "(SKIP) $subj: cannot read $input in $(pwd)" && continue
   # motion correct, strip first 4 volumes
   # a la Spin History Artifact slide 6/26 in pestica_tutorail_afni_v2.pdf
   moco=${subj}_$(basename $input .nii.gz).moco
   #3dvolreg -prefix $moco -maxite 60 -zpad 8 "${input}[4..$]" 
   # this also removes first 4 volumes. assume scanner already did this for us
   #
   #discussion:
   # http://www.nitrc.org/forum/forum.php?thread_id=3485&forum_id=1456 (why motion correct before pestica)
   #
   # see also  http://www.personal.reading.ac.uk/~sxs07itj/web/AFNI_motion.html
   # 

   #[ -n "$(find ./ -name $moco\*)" ] && echo "(SKIP) $subj: $moco already exists" && continue
   [ -r .pestica.complete ] && echo "(SKIP) $subj: finished $(tail -n1 .pestica.complete)" && continue

   3dvolreg -overwrite -prefix $moco -base "${input}[0]" -dfile ${subj}_rest_motion.txt -maxite 60 -zpad 8 "${input}" 
   # --tshift -Fourier # no slice correction: slide 7/26, PESTICA dependent on slice timing
   # maxite is max iterations, 60 > 3 x default
   # zpad zero value voxels add to edges on rotation that will later be stripped off. why? donno
   # 

   run_pestica.sh -d $moco -m -b #| tee $subj.pestica.log  # captured instead by tee from outside function

   mv pestica.incomplete .pestica.complete
   date +%F+%H:%M:%S >> .pestica.complete
}

find /Volumes/TX/Autism_Faces/subject_data/byID/ -maxdepth 2 -mindepth 2 -name rest -type d | while read restdir; do
   # don't do too many jobs at once
   numjobs=$(jobs  |wc -l )
   while [ $numjobs -ge $MAXJOBS ]; do echo "waiting 300s b/c numjobs >= max $numjobs>=$MAXJOBS"; numjobs=$(jobs  |wc -l ); sleep 300;done
   echo "running $(basename $(dirname $restdir)) (job #$((($numjobs+1))) )"
   runpestica $restdir 2>&1 | tee -a $restdir/pestica.log &
   #break # only testing. just run on one guy
done 
