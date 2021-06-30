 clear all ;
clc

f=fopen('accuercy1.csv');
N=27;data=cell(1,N);M=30;h=zeros(1,M);acc=zeros(M,N);r=zeros(M,N);



for i=1:N
    data{i}=fscanf(f,'%s',1);
end
for i=1:M
    h(i)=fscanf(f,'%i',1);
   
    acc(i,:)=fscanf(f,'%g',N);
end

%   P  | Ranking Type    | Ties get ... rank | V = [1 2 2 4] -> R =
%   ----------------------------------------------------------------------
%     1  | Dense (default) | same              |   1  2   2  3
%     2  | Ordinal         | consecutive       |   1  2   3  4
%     3  | Competition     | same minimum      |   1  2   2  4
%     4  | Modified Comp.  | same maximum      |   1  3   3  4
%     5  | Fractional      | same average      |   1 2.5 2.5 4
  y = inputdlg({'Enter number of Ranking Type:'},'Customer', [1 50]); 
  y=str2num(y{1});
RankingType=y;
for i=1:N 
x=ranknum(acc(:,i),RankingType);%== STANDARD COMPETITION RANKING "1224"
r(:,i)=x;
end

     a=size(r);

for x = 1 : a
      average(x) = mean( r(x,:) ) ;
            stdev(x) = std( r(x,:) ) ;
end


mnm=min(average);
xaxiex=find(average == mnm);
Values = stdev(xaxiex);
xaxiex=xaxiex*10;

err = stdev;

errorbar(h,average,err,'-s','MarkerSize',10,...
    'MarkerEdgeColor','red','MarkerFaceColor','red')

title('Errorbar Plot audi albtoush')
hold on
% plot(h, average, 'LineWidth', 2);
grid
xlabel('Number Of Element');
ylabel('stander error');
x=1:xaxiex;
y=mnm+Values;
% legend('Data','Fitted Curve','Location','SouthEast')

plot(x,y*ones(size(x)) ,'LineWidth',2, 'MarkerFaceColor','g')
hold off
