clear;
clc;
tickerlistaaa={'SPY','QQQ','GLD','USO'};
tickernames=tickerlistaaa;
%tickernames={'S&P500','NASDAQ','Gold','Light Oil'};
loss_b_range=-2;
Benchmark={'GARCH','GJR-GARCH','HAR'};

try
    Spec_data=load('RV_Pool_270_Spec_tbl');
catch
    record_mdlspec;
    Spec_data=load('RV_Pool_270_Spec_tbl');
end

%% The benchmark indexes
bench_ind=zeros(size(Benchmark));
family_class=Spec_data.Mdl_Class;
for s=1:numel(bench_ind)
    sel_bench=Benchmark{s};
    idx_bench=find(strcmp(family_class,sel_bench));
    bench_ind(s)=idx_bench(1);
    
end

i_l=5;
nbin=10;
rng(0);
figure,
for ta=1:numel(tickerlistaaa)
    flname=[tickerlistaaa{ta},'_Pool_M5_OOS_2014_2020.mat'];
    load(flname,'oosdate','oos_ser','TF1SMP','TF2SMP','tbl0');
    oos_ser(oos_ser>.01)=.01;
    oos_ser(oos_ser<1e-8)=1e-8;
    oos_ser(isnan(oos_ser))=.01;
    oos_ser_tested=oos_ser;
    poolset_ser=oos_ser_tested;
    target=tbl0{TF1SMP:end,'RVDaily'};
    modelscount=size(oos_ser,2);
    iter=0;
    for l=1:numel(loss_b_range)
        iter=iter+1;
        Perf(iter,:)=robust_loss_fn(poolset_ser,target,loss_b_range(l));
        
    end
    Perf=abs(Perf);
    Perf(Perf>5*mean(Perf(:,1)))=5*mean(Perf(:,1));
    Perf_bar=real(mean(Perf,1,'omitnan'));
    
    
    
    subplot(numel(tickerlistaaa)/2,2,ta);
    highplotrange=prctile(Perf_bar,99.5);
    lowplotrange=prctile(Perf_bar,0.5);
    Up_lim=highplotrange;
    Low_lim=lowplotrange;
    
    cdf=zeros(1,nbin);
    supp_points=linspace(Low_lim,Up_lim,nbin);
    for s=1:nbin
        cdf(s)=sum(Perf_bar<=supp_points(s));
    end
    cdf=[0,cdf];
    pdf=diff(cdf)/numel(Perf_bar);
    lim_pdf=floor(max(pdf)*95)/100;
    
    plotrng=(highplotrange-lowplotrange)/nbin;
    ax1=histogram(Perf_bar,lowplotrange:plotrng:highplotrange,'DisplayStyle','bar','Normalization','probability');
    hold all;
    %ax1=histogram(Perf_bar,20,'DisplayStyle','bar','Normalization','probability');hold all;
    y_steps=lim_pdf/(nbin);
    y_range=0:y_steps:lim_pdf;
    
    % GARCH
    ax2=plot(Perf_bar(bench_ind(1))*ones(numel(y_range),1),y_range,'--k','LineWidth',1.5);
    % GJR-GARCH
    ax3=plot(Perf_bar(bench_ind(2))*ones(numel(y_range),1),y_range,'-.k','LineWidth',1.5);
    % HAR
    ax4=plot(Perf_bar(bench_ind(3))*ones(numel(y_range),1),y_range,':k','LineWidth',2.5);
    
    grid('on')
    title(tickernames{ta});
    xlabel('Loss');
    ylabel('Density');
    legend([ax2,ax3,ax4],'GARCH','GJR-GARCH','HAR','Location','best');
    legend('boxoff');
    hold off;
    set(gcf,'WindowState','maximized');
end

