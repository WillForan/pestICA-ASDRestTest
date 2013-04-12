function cmp = getRespCorr

  %seconds to show in plot
  plotmin=100;
  plotmax=150;
  plottitle='';
  subj='';
  fig=figure;
  set(fig,'PaperPosition',[0 0 40 10]);
  function c = resampXandcorrtoY(X,Y)
     %Xr = resample(X, length(Y)  , length(X) ); 
     %time = resample(1:300,length(Y),300)
     Xr = resample(X, length(Y)  , length(X) ); % pretty good
     %Xr = pchip(1:length(X),X,1:length(Y) )';  % bad
     %Xr = spline(1:length(X),X,1:length(Y) )'; % also bad

     c  = corr( Xr, Y );

     % check resampling -- looks good with resample
     %%timeX=linspace(0,300,length(X));
     %%i=find(timeX>=plotmin & timeX <=plotmax);
     %%plot( timeX(i), X(i))
     %%hold on
     %%i=find(time>=plotmin & time <=plotmax);
     %%plot(time(i), Xr(i), 'ro:');
     %%title(typ)
     %%legend({'orig','resample'})

     %%pause
     %%hold off


     time = linspace(0,300,length(Y));
     i=find(time>=plotmin & time <=plotmax);

     plot(time(i), [Xr(i),Y(i)]);
     legend({'physio','est'});
     title([ typ ':' plottitle ': ' num2str(c)]);
     plotfname=['cmpfigs/' subj '_' typ '_' plottitle '.png'];
     saveas(fig,plotfname); 
     %print(fig,'-djpeg',plotfname);

  end
   
  % subjs for whom we have a mat resp file
  list=ls('actual/*.respph.1D');
  
  % find where in the ls output we start the subject id named mat files
  subjlistidx=regexp(list,'\d{3}.respph.1D');
  corrs=cell(length(subjlistidx),5);
  
  for i=1:length(subjlistidx)
    % subject id's are always 3 in length
    % so get the first 3 characters (subjid) of the *.mat match
    m=subjlistidx(i);
    subj=list(m:m+2);
    disp(subj)
    
  
   % load and save second pass irf phases
   estphase = load([ 'est/' subj '_ir2.mat' ]);

   % go through each phase
   % get init, trunc, and phase correlations
   for typ={'card','resp'}
     typ=typ{1};
     plottitle='raw';
     raw = load( ['actual/' subj '.' typ '_raw.1D'    ] );
     est = load( ['est/'   subj '.' typ '_rawest.dat' ] );
     cmp.(typ).(['s' subj]).init  = resampXandcorrtoY(raw, est);

     plottitle='truncated range';
     trunc1D=ls(['actual/' subj '.' typ '_range*.1D' ]);
     raw=load( trunc1D(1:end-1) );
     est=load(    ['est/'   subj '.' typ '_est.dat'    ]           );
     cmp.(typ).(['s' subj]).trunc = resampXandcorrtoY(raw,est);

     plottitle='phase';
     raw=load( ['actual/' subj '.' typ 'ph.1D'  ] );
     cmp.(typ).(['s' subj]).phase = resampXandcorrtoY(sin(raw), sin(estphase.([typ 'ph' ]) ) );
   end
  
  end
  
  %% print it
  
  tsv=fopen('corrs.tsv','w');
  for t=fieldnames(cmp)';
    for s=fieldnames(cmp.(t{1}))';
      for n=fieldnames(cmp.(t{1}).(s{1}))';
        fprintf(tsv,'%s\t%s\t%s\t%f\n', t{1}, s{1}, n{1}, cmp.(t{1}).(s{1}).(n{1}) );
      end
    end
  end
  fclose(tsv);

end
