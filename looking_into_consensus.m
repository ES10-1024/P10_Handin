%Looking into consensus 
%% 
c=scaled_standard_constants; 

c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix to add consumption and inflow (integral) 
 c.A_2 = tril(ones(c.Nc,c.Nc));
lowTran=c.A_2*c.A_1; 

x1=lowTran*Xsave(:,1,end,1)*1000;
x3=lowTran*Xsave(:,3,end,1)*1000;
x1-x3

x1=lowTran*Xsave(:,1,end,1)*1000;
x2=lowTran*Xsave(:,2,end,1)*1000;
x1-x2

%% 
for k=1:10000
    diffx1(:,k)=Xsave(:,1,k,1)-zSave(:,:,k); 
end 

%diffx1=diffx1(1:2:end,:); 

%% 
for k=1:10000
    if k<=9
        rho=saveRho(k,1); 
        rhox1(k,1)=rho/2*((Xsave(:,1,k)-zSave(:,1,k))'*(Xsave(:,1,k)-zSave(:,1,k)));
    elseif k>=30 
        rho=saveRho(end,1)*500; 
        rhox1(k,1)=rho/2*((Xsave(:,1,k)-zSave(:,1,k))'*(Xsave(:,1,k)-zSave(:,1,k)));
    else 
        rho=saveRho(end,1); 
        rhox1(k,1)=rho/2*((Xsave(:,1,k)-zSave(:,1,k))'*(Xsave(:,1,k)-zSave(:,1,k)));
    end 
end 
  
%% 
for k=1:10000
    lambdatermx1(k,1)=lambdaSave(:,1,k)'*(Xsave(:,1,k)-zSave(:,1,k));
    lambdatermx2(k,1)=lambdaSave(:,1,k)'*(Xsave(:,1,k)-zSave(:,1,k));
    lambdatermx3(k,1)=lambdaSave(:,1,k)'*(Xsave(:,1,k)-zSave(:,1,k));
end 

%%
f=figure
hold on 
yyaxis left 
plot(procentDifference)
ylim([-1 1])
xlim([0 4000])
grid 
yline(0) 
ylabel('Performance')
set(gca,'fontname','times')

yyaxis right 
%h1=stairs(rhox1);
h2=stairs(lambdatermx1);
ylim([-2e-3 2e-3])
xlim([0 4000])
ylabel('$\lambda$ term', 'Interpreter', 'latex');
%ylabel('\boldmath$\lambda_i^{k\top}(\mathbf{x}_i-\mathbf{z}^k)$','Interpreter','latex');
xlabel('Iterations')
set(gca,'fontname','times')
% Create legend for items plotted on the right y-axis
%legend([h1 h2], {'Rho', 'Lambda'});

hold off 
exportgraphics(f,'lambdaTerm.pdf','ContentType','vector') 

%% 

for k=1:200
    if k<=10 
        rho=saveRho(k,1); 
        rhox1(k,1)=rho/2*((Xsave(:,1,k,1)-zSave(:,1,k,1))'*(Xsave(:,1,k,1)-zSave(:,1,k,1)));
    elseif k>=30 
        rho=saveRho(end,1)*500; 
        rhox1(k,1)=rho/2*((Xsave(:,1,k,1)-zSave(:,1,k,1))'*(Xsave(:,1,k,1)-zSave(:,1,k,1)));
    else 
        rho=saveRho(end,1); 
        rhox1(k,1)=rho/2*((Xsave(:,1,k,1)-zSave(:,1,k,1))'*(Xsave(:,1,k,1)-zSave(:,1,k,1)));
    end 
  
end 
%% 
for k=1:200
    lambdatermx1(k,1)=lambdaSave(:,1,k,1)'*(Xsave(:,1,k,1)-zSave(:,1,k,1));
end 

%% 


f = figure;
hold on;

yyaxis left;
plot(procentDifference(:,1));
xline(30);
ylim([-1.5 1.5]);
xlim([0 200]);
grid;
yline(0);
ylabel('Performance');
set(gca,'fontname','times');

yyaxis right;
h1 = plot(rhox1);
h2 = plot(lambdatermx1);
ylim([-4e-3 4e-3]);
xlim([0 200]);
ylabel('$\rho$ \& $\lambda$ term', 'Interpreter', 'latex');
xlabel('Iterations');
set(gca,'fontname','times');
text_str = '500 $\rho$';

text(31,-3.5e-3,text_str, 'Interpreter', 'latex', 'FontSize', 12, 'FontName', 'Times New Roman');
% Create legend for items plotted on the right y-axis
legend([h1 h2], {'$\rho$ term', '$\lambda$ term'}, 'Interpreter', 'latex');

hold off;

exportgraphics(f,'rhoTerm.pdf','ContentType','vector') 

