#!/usr/bin/env bash

# remove link dirs, remake
for d in mat est brain actual;do
   [ -d $d ] && rm -r $d
   mkdir $d
done
#
# get some mat files
ln -s /Volumes/TX/Autism_Faces/O\'Hearn\ Physio\ Data/2*mat mat/


# make some mat files
for f in  /Volumes/TX/Autism_Faces/O\'Hearn\ Physio\ Data/*{-12,13,14}.txt; do
 file=$(basename "$f" .txt)
 sed 's///g' "$f" |
 perl -F, -slane '
  next unless $.>22; # header should always be the first 22 lines
  
  # columns are: time, TR trigger, pulse, ECG, EtCO2 [, comment]
  # *mat columns from acq are: pulse (SPO2)*, TR trigger , resp, resprate, pulse rate
  # want to make txt like mat, so print column 
  print join(",",@F[2,1,4,3,0]); # 2 is pulse,1 is trigger, 4 is resp,  3 is ECG (electrodes) not recored, 0 is time (junk)
 ' > "mat/$file.csv"
 matlab -nodisplay <<<"data=dlmread('mat/$file.csv'); save('mat/$file.mat','data') " && rm mat/$file.csv
done


# get the resp files pestICA created
# get the brain images used by pestICA to create the resp estimates
for mat in mat/*.mat; do
 s=$(basename $mat .mat)
 # remove txt del
 s=${s/-*/}


 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/*moco_pestica/resp_rawest.dat est/$s.resp_rawest.dat
 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/*moco_pestica/card_rawest.dat est/$s.card_rawest.dat

 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/*moco_pestica/resp_pestica.dat est/$s.resp_est.dat
 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/*moco_pestica/card_pestica.dat est/$s.card_est.dat

 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/*moco_pestica/impulse_responses_secondpass.mat est/${s}_ir2.mat

 ln -s /Volumes/TX/Autism_Rest/subject_data/byID/$s/rest/${s}_rest.moco+orig.* brain/

 matlab <<HERDOC

  load $mat
  
  %% three types of physio
  %    from txt, from acq (bioread), or acq saved as mat

  if( regexp('$mat','-') ) % from txt, has a - delimn
    card=data(:,1); %card is index 1
    resp=data(:,3); %resp is index 3
  else
    % we want the resp and card for rest
    % rest is the last experiment
    [vals,indx] = findpeaks(data(:,2),'MINPEAKHEIGHT',4,'MINPEAKDISTANCE',130);
    starts=indx(find([Inf; diff(indx)]>310));
    ends=[indx(find(diff(indx)>350)); indx(end)] + 1.5*100;

    card=data(starts(end):ends(end),1); %card is index 1
    resp=data(starts(end):ends(end),3); %resp is index 3
  end

  s='$mat', m=mean([card, resp]), r=range([card, resp]), s=std([card, resp])

  % write out actual raw physio data as subj.*_raw.1D for use later
  fp=fopen('actual/$s.resp_raw.1D','w');fprintf(fp,'%g\n',resp); fclose(fp);
  fp=fopen('actual/$s.card_raw.1D','w');fprintf(fp,'%g\n',card); fclose(fp);

  %% treat actual data like estimates 
  addpath(genpath('/Volumes/TX/Autism_Faces/pestica/pestica_afni_v2/'))
  resp=view_and_correct_estimator(resp,'brain/${s}_rest.moco+orig','rpmu',1);
  card=view_and_correct_estimator(card,'brain/${s}_rest.moco+orig','cpmu',1);

  % write out filterd data to *range*
  fp=fopen('actual/$s.resp_range10_24.1D','w');fprintf(fp,'%g\n',resp); fclose(fp);
  fp=fopen('actual/$s.card_range48_85.1D','w');fprintf(fp,'%g\n',card); fclose(fp);

HERDOC

 3dretroicor -prefix tempepi -threshold 0 -order 1 \
             -card actual/${s}.card_range48_85.1D -cardphase actual/${s}.cardph.1D \
             -resp actual/${s}.resp_range10_24.1D -respphase actual/${s}.respph.1D \
            brain/${s}_rest.moco+orig
 
 rm tempepi*
 rm *batch*png
done
