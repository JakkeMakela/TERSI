

%Used for plotting, mainly
ContractsInPlace=[0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5];
%Define the societies by number of contract
C0=[1];
C1=[17, 9, 5, 3,2];
C2=[4,  6,  7,  10, 11, 13, 18, 19, 21, 25];
C3=[8,  12, 14, 15, 20, 22, 23, 26, 27, 29];
C4=[16, 24, 28, 30, 31];
C5=[32];
ContractsByNumber=[C0,C1,C2,C3,C4,C5];

%When various contracts are on
N=1; F=32; %First one has no contracts
T=[];E=[];R=[];S=[];I=[];
for kk=1:32;
    tr=dec2bin(kk-1,5);
    if (tr(1)=='1'); T=[T;kk]; end;
    if (tr(2)=='1'); E=[E;kk]; end;
    if (tr(3)=='1'); R=[R;kk]; end;
    if (tr(4)=='1'); S=[S;kk]; end;
    if (tr(5)=='1'); I=[I;kk]; end;
end;



figure;
tittext=sprintf('%i / %0.2f / %0.2f',Parameter.Crop_target_start,Parameter.SustainabilityMaximumRatio,Parameter.HarvestMaximumRatio);
for socnum=SocietiesToCheck;
    profitnow(socnum)=mean(CurrentProfit(:,socnum));
    stdnow(socnum)=std(CurrentProfit(:,socnum));
    deadprofits(socnum)=mean(DeadProfit(:,socnum));
    deaths(socnum)=mean(Deaths(:,socnum));
end;
plot(profitnow(ContractsByNumber),'ko');
hold on;
%Draw lines for number of contracts
ymax=max(profitnow+deadprofits); plot([6.5 6.5],[0 ymax],'g--');
plot([16.5 16.5],[0 ymax],'g--');  plot([26.5 26.5],[0 ymax],'g--');
plot(deadprofits(ContractsByNumber),'kd');
plot(profitnow(ContractsByNumber)+deadprofits(ContractsByNumber),'ks');
grid on; xlabel('#'); ylabel('Profit'); title(tittext);
hold off;

%figure;
%plot(DeadProfit(:,1)+CurrentProfit(:,1),'k.-');
%hold on;
%plot(DeadProfit(:,17)+CurrentProfit(:,17),'r');
%plot(DeadProfit(:,9)+CurrentProfit(:,9),'m');
%plot(DeadProfit(:,5)+CurrentProfit(:,5),'g');
%plot(DeadProfit(:,3)+CurrentProfit(:,3),'c');
%plot(DeadProfit(:,2)+CurrentProfit(:,2),'b');
%plot(DeadProfit(:,1)+CurrentProfit(:,1),'k.-');
%hold off;
%title('Current+Dead,Single-contract; Nil=k, T=r, E=m, R=g, S=c, I=b');
