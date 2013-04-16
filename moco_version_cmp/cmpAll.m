%%% 
%
% plot and corr actual and est resp of 267
%
%%%
TRsec      =1.5;
SampleHz   =100;
ParadigmSec=300;
 
cwd=pwd();

%% prepair for afni reading
warning off;addpath('/home/foranw/bin/afni/matlab/');warning on;
Opt.Format = 'matrix';

%% actual
load /home/foranw/src/physo/pestica/AutFace/267_v2/267.mat
[vals,indx] = findpeaks(data(:,2),'MINPEAKHEIGHT',4,'MINPEAKDISTANCE',130);
starts=indx(find([Inf; diff(indx)]>310));
ends=[indx(find(diff(indx)>350)); indx(end)] + TRsec*SampleHz;
actual_resp_orig=data(starts(end):(ends(end)-1),3); %resp is index 3


%% Setup for each moco/version pair
runs(1).name   ='V2moco';
runs(1).dir    ='/home/foranw/src/physo/pestica/AutFace/267_v2/rest.moco_pestica/';
runs(1).pestica='/home/foranw/src/physo/pestica/pestica_afni_v2';
runs(1).brain  ='rest.moco+orig';
runs(1).mask   ='rest.moco.brain+orig';

runs(2)=runs(1);
runs(2).name   ='V2nomoco';
runs(2).dir    ='/home/foranw/src/physo/pestica/AutFace/267_v2/rest_pestica/';
runs(2).brain  ='rest+orig';
runs(2).mask   ='rest.brain+orig';

runs(3).name   ='V1moco';
runs(3).dir    ='/home/foranw/src/physo/pestica/AutFace/267_pesticav1.3/';
runs(3).pestica='/home/foranw/src/physo/pestica/pestica_afni_v1_3/';
runs(3).brain  ='rest.moco+orig';
runs(3).mask   ='rest.moco.brain+orig';

runs(4)=runs(3);
runs(4).name   ='V1nomoco';
runs(4).brain  ='rest+orig';
runs(4).mask   ='rest.brain+orig';


runs(5)=runs(1);
runs(5).name   ='V2mocoTrunc';
runs(5).dir    ='/home/foranw/src/physo/pestica/AutFace/267_v2/rest.moco.resample_pestica/';
runs(5).brain  ='rest.moco.resample+orig';
runs(5).mask   ='rest.moco.resample.brain+orig';


runs(6)=runs(3);
runs(6).name   ='V1mocoTrunc';
runs(6).brain  ='rest.moco.resample+orig';
runs(6).mask   ='rest.moco.resample.brain+orig';

for i=runs

  %% Setup
  setenv('PESTICA_DIR', i.pestica);
  addpath(genpath(getenv('PESTICA_DIR')));
  cd(i.dir);
  
  %% truncate actual resp to match what we have.. if needed
  % get number of volumes, set time
  brain=i.brain;
  if(~exist(brain,'file') ) 
   brain=['rest_pestica/' brain];
  end
  [err, ima, ainfo, ErrMessage]=BrikLoad(i.brain, Opt);
  epi_tdim=ainfo.TAXIS_NUMS(1);
  TR=double(ainfo.TAXIS_FLOATS(2));
  % sanity check
  if( TR ~= TRsec ); fprintf('** TR is funky!: afni %f, expected %f\n',TR,TRsec); end
  % chop volumes from actual start if too few in brain images
  if( TR*epi_tdim ~= ParadigmSec )
    diffSec=ParadigmSec-TR*epi_tdim;
    fprintf('++ volume diff (%.2fsec), expect %.3f < %.3f\n',diffSec, TR*epi_tdim,ParadigmSec)
    % make new start by taking the difference out from the top
    actual_resp=actual_resp_orig((diffSec*SampleHz+1):end);
    ParadigmSec_used=TR*epi_tdim;
  else
    actual_resp=actual_resp_orig;
    ParadigmSec_used=ParadigmSec;
  end
  
  actual_length=length(actual_resp)/SampleHz;
  if( actual_length ~= TR*epi_tdim); fprintf('** times do not match!: afni %f, expected %f\n',TR*epi_tdim,actual_length); end
  
  actual_time=linspace(0,ParadigmSec_used,length(actual_resp));
  
  %% RUN
  [estrawcard,estrawresp]=apply_PESTICA2(15,i.brain,i.mask,'siemens-alt-asc');
  % no significance possible: number of data points MUST be greater than 4 for this slice
  % no significance possible: number of data points MUST be greater than 4 for this slice

  %% view and correct is different for pestica versions
  if(i.name(2) == '2')
     resp_auto=view_and_correct_estimator(estrawresp,i.brain,'r',1);
     % From rest.moco+orig header, using slices=29 and TR=1.500000
  else
     figure;
     resp_auto=view_and_correct_estimator(estrawresp,i.brain,'r');
  end 


  
  %% times and resamples
  est_time    =linspace(0,ParadigmSec_used,length(resp_auto  ));
  est_resample=resample(resp_auto,length(actual_resp),length(resp_auto))';

  % get correlation
  c=corr(actual_resp,est_resample);
  
  %% print some stuff about where we are
  fprintf('%s: %s\n%s\t%s\n%f\n\n', i.name, pwd, i.brain, i.mask,c)
  which apply_PESTICA2
  which view_and_correct_estimator

  a=figure;
  plot(actual_time,[actual_resp,est_resample]);
  legend({'actual','resp'}); hold on;
  plot(est_time, resp_auto, 'r:');
  title([ '267, ' i.name ' cor: ' num2str(c) ]);


  %% check raw and esimaters on file
  % but only if they are going to be the same length
  if(ParadigmSec_used == ParadigmSec && i.name(2)=='2')
     basedir='/home/foranw/src/pestICAcmp/';

     %est = load( [i.dir '/resp_rawest.dat' ] );  % confirms file names and deterministic
     est = load( [basedir 'est/267.resp_rawest.dat' ] );
     fprintf('corr resp_rawest.dat and applyPESTICA: %f\n', corr(est,estrawresp') )

     %est = load( [i.dir '/resp_pestica.dat' ] ); % confirms file names and deterministic
     est=load(  [basedir 'est/267.resp_est.dat' ] );
     fprintf('corr resp_est.dat and resp_auto: %f\n',corr(est,resp_auto'))
  end


  for r={[70 115],[130 210]}
   r=r{1};
   idxs = find(actual_time>=r(1) & actual_time<=r(2));

   est_idxs = find(est_time>=r(1) & est_time<=r(2));


   f=figure;
   plot(actual_time(idxs),[actual_resp(idxs),est_resample(idxs)]);
   legend({'actual','resp'})
   hold on; plot(est_time(est_idxs), resp_auto(est_idxs), 'r:');
   title([ '267, ' i.name ' cor: ' num2str(c) ]);
   saveas(f,[ cwd '/267_resp_' i.name num2str(r(1)) '_' num2str(r(2)) '.jpg']);
   close(f)
  end
end
