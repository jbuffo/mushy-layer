% Plot  typical AMR solutions for darcy brinkman problems 
function Fig5FixedPorosityConvectionPlots(dataFolderNu, dataFolderVariablePorosity, figureDirectory)

if nargin < 3
   % dataFolderNu = getDataDir('AMRConvergenceTest/ConvectionDB/chi0.4-Da0.01-Ra1e5/');
   % dataFolderVariablePorosity = getDataDir('AMRConvergenceTest/DBVariablePorosityGaussian1proc-t1.6-v2/');
    
    base_dir = '/home/parkinsonjl/mnt/sharedStorage/TestFinal/';
    dataFolderNu = fullfile(base_dir, '/ConvectionDB-cfl0.1/chi0.4-Da1.0e-02-Ra1.0e+05/');
    dataFolderVariablePorosity = fullfile(base_dir, '/FixedPorousHole-1proc/');
    
    %thisFilename = mfilename('fullpath');
    %figureDirectory = strrep(thisFilename, 'Fig5FixedPorosityConvectionPlots', '');
    figureDirectory = base_dir;
end

close all;
  
figureName =  [figureDirectory, 'Fig5FixedPorousFigure']; %[dataFolderNu, 'benchmark2Convergence'];
saveFigure = true;

NuUniformRes = 128;
NuAMRRes = 128;

%highRes = getFinalPlotFile([dataFolderNu, plotPrefixUniform(gridRes(end)*2)]);

h = figure();
h.Position = [200 200 1200 500];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(h,'Units','Inches');
h.Position = [2.0 2.0 6.5 2.9];
% Caption font size is 8pt
textFontSize = 8;
labelFontSize=9;
legendFontSize = 8;
domainFontSize = 8;

set(0, 'defaultlinelinewidth',1);
set(0, 'defaultaxeslinewidth',1);
set(0, 'defaultpatchlinewidth',1);
set(0, 'defaultAxesFontSize', textFontSize);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

axHeight = 0.55;
axBottom = 0.25;

m = 1; n = 3;
subplot(m, n, 1)
axBCs = gca;
axBCs.Position = [0.05 axBottom 0.25 axHeight];


xlim([0 1]);
ylim([0 1]);
box on;

axBCs.YTick = [];
axBCs.XTick = [];
daspect([1 1 1]);


text(0.1, 0.55, {'Solve eqs. (3) to (6) with:', '$S=0, Pr=1$, and', '(b) $\chi=0.4$, or', '(c) $\chi$ given by eq. (40).'}, ...
    'FontSize', domainFontSize);

insulatingStr = {'b: $\partial H/\partial x = \partial \Theta / \partial x = 0, \mathbf{U} = 0.$', ...
    'c: periodic.'};

text(-0.12, -0.02, '$H=H(\theta=1, \chi=0.4), \Theta=0, \mathbf{U} = 0.$', ...
    'FontSize', domainFontSize, 'Rotation', 90);
text(1.08 , -0.02, '$H=H(\theta=0, \chi=0.4), \Theta=0, \mathbf{U} = 0.$', ...
    'FontSize', domainFontSize, 'Rotation', 90);

text(-0.01, 1.08 ,insulatingStr, 'FontSize', domainFontSize);
text(-0.01, -0.11, insulatingStr, 'FontSize', domainFontSize);

%axis arrows
annotation('arrow',[0.03 0.07], [0.06 0.06], 'HeadWidth', 5, 'HeadLength', 5);
annotation('arrow',[0.03 0.03], [0.06 0.16], 'HeadWidth', 5, 'HeadLength', 5);
text(-0.05, -0.4, '$x$', 'FontSize', textFontSize);
text(-0.19 , -0.2   , '$z$', 'FontSize', textFontSize);

text(0.04, 0.93, '(a)', 'FontSize', labelFontSize);

subplot(m, n, 2)

%AMRsol = getFinalPlotFile([dataFolder, plotPrefixUniform(32)]);
AMRsol = getFinalPlotFile(fullfile(dataFolderNu, plotPrefixAMR(NuAMRRes)));
UniformFineSol = getFinalPlotFile(fullfile(dataFolderNu, plotPrefixUniform(NuUniformRes)));
makeSubplot(AMRsol, UniformFineSol, [0.35 axBottom 0.3 axHeight])


text(0.03, 0.92, '(b)', 'FontSize', labelFontSize, 'Color', [0 0 0]);
%text(-0.2, 1.2, '(b)', 'FontSize', 16);

subplot(m, n, 3);

AMRsol = getFinalPlotFile(fullfile(dataFolderVariablePorosity, ...
    'AMR-Subcycle-Reflux-Freestream0.99-MaxLevel1-ref2-DBVariablePorosity-32-'));
UniformFineSol = getFinalPlotFile(fullfile(dataFolderVariablePorosity, ...
    'Uniform-DBVariablePorosity-64-'));

makeSubplot(AMRsol, UniformFineSol, [0.65 axBottom 0.3 axHeight])


axErr = gca;

 
text(0.02, 0.92, '(c)', 'FontSize', labelFontSize, 'Color', [0 0 0]);

set(h,'Units','Inches');
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
%set(h, 'InvertHardCopy', 'off'); % keep white text white

if saveFigure
    fprintf('Saved to %s \n', figureName);
    print(h,[figureName, '.eps'],'-depsc','-r50')
    print(h,[figureName, '.png'],'-dpng','-r1000')
    print(h,[figureName, '.svg'],'-dsvg','-r0')
    savefig([figureName, '.fig'])
end

end


function err = getErr(dataFolder, prefixFunc, gridRes, highResML)
err = NaN*ones(length(gridRes), 1);

exactNu = 1.41008;

for f =1:length(gridRes)
    thisRes = gridRes(f);
    thisFolder = [dataFolder, prefixFunc(thisRes)];
    
    thisML = getFinalPlotFile([dataFolder, prefixFunc(thisRes)]);
    
    if length(thisML.levelArray) > 0
    MLdiff =  highResML.diff(thisML, [thisML.components.Temperature], ...
                            [thisML.components.Temperature]);
             
                    
    [L1, L2, Max, Sum] = AMRSum(MLdiff, thisML.components.Temperature);
        
    err(f) = L1;
    end
    
    
    %diags = getDiagnostics([thisFolder, '/diagnostics.out']);
    %fprintf('Loading diags %s \n', thisFolder);
    %if isfield(diags,'Nusselt')
    %Nuerr = abs(diags.Nusselt(end) - exactNu)/exactNu;   
    %err(f) = Nuerr;
    %end
    
    
   %errFile = [thisFolder, '/err.mat'];
   % if exist(errFile, 'file') == 2
   %     load(errFile)
   % else
        %output = getFinalPlotFile(thisFolder);
       
        %if length(output.levelArray) > 0
        %    Terr = output.dataForComp(output.components.Terr);
        %    Te = squeeze(Terr(2,:));
        %    e.meanTerr =  mean(abs(Te));
        %    save(errFile, 'e');
        %end
   % end
    
   % err(f) = e.meanTerr;
end

end

function f = plotPrefixAMR(N)
f =  ['VM-Subcycle-Reflux-Freestream0.95-MaxLevel1-ref2-convectionDB-',num2str(N),'-'];
end

function f = plotPrefixUniform(N)
f =  ['Uniform-convectionDB-',num2str(N),'-'];
end



function makeSubplot(AMRsol,UniformFineSol, axisExtent)

onLaptop = false;
[~, name] = system('hostname'); 
name = strtrim(name);
if strcmp(name, 'atmlxlap005')
onLaptop = true;
end

T = AMRsol.dataForComp(AMRsol.components.Temperature).';
psi = AMRsol.dataForComp(AMRsol.components.streamfunction).';
psiUniform = UniformFineSol.dataForComp(UniformFineSol.components.streamfunction).';
Tuniform = UniformFineSol.dataForComp(UniformFineSol.components.Temperature).';

if max(max(T)) > 1.5
   T = T/2; 
   Tuniform =Tuniform/2;
end

[X,Y] = AMRsol.grid();
[XUniform,YUniform] = UniformFineSol.grid();
%Create smooth psi


fprintf('Max psiUniform = %.3g \n', max(max(psiUniform)));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Psi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
psiUniform = max(psiUniform, 0);
psi = max(psi, 0);
% Plot psi uniform because it's smoother
%psi = psiUniform;
axPsi = gca;
%Ncontours = min(10, round(max(max(psiUniform))/1.5e-5));
%v =  linspace(4e-6,max(max(psiUniform)), Ncontours) ;

%[Cpsi, hpsi] = contour(XUniform,YUniform,psiUniform, v); 
%[Cpsi, hpsi] = contour(XUniform,YUniform,plot_T); 
%pcolor(X,Y,psi); 
pcolor(XUniform,YUniform, psiUniform);

daspect([1 1 1]);

cmap = flipud(plasma(100));
cmap = flipud(viridis);
colormap(axPsi,cmap);

box on;

cPsi = colorbar(axPsi,'Location', 'southoutside');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axTemperature = axes;

plot_T = T*2-1;
plot_TUniform = Tuniform*2 - 1;
v = linspace(-0.98,0.98,11);
[CTemp, hTemp] = contour(XUniform, YUniform, plot_TUniform, v);
hTemp.LineWidth = 2.0;

%pcolor(X,Y,T*2-1); 
%pcolor(X,Y,psiUniform); 

daspect([1 1 1]);

colormap(axTemperature, bluewhitered(257));
cTemp = colorbar(axTemperature, 'Location', 'northoutside');
cTemp.Ticks = [min(min(plot_T))*0.98 max(max(plot_T))*0.98];
cTemp.TickLabels = {'0', '1'};
%cTemp.Position(2) = cTemp.Position(2)-0.05;
cTemp.Label.String = '\theta';
oldPos = cTemp.Label.Position;
if onLaptop
    cTempLabelOffset = 1.2;
else
%    cTempLabelOffset = -0.8;
    cTempLabelOffset = -1.0;
end
cTemp.Label.Position = [oldPos(1) oldPos(2)+cTempLabelOffset];


box on;
%set(axTemperature, 'Layer', 'top');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
linkaxes([axTemperature,axPsi]);
axPsi.Position = axisExtent;
axTemperature.Position = axisExtent;


set(axPsi, 'Layer', 'top');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot meshes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on
meshColor(1, :) = [1 1 1];
meshColor(2, :) = [0 0 0 ];
meshColor(3, :) = [0 0 0];

opacity(1) = 0.0;
opacity(2) = 0.0;
opacity(3) = 0.0;

edgeColor(1, :) = [1 1 1]; % black
edgeColor(2, :) = [1 0 1]; % magenta
edgeColor(3, :) = [0 1 1]; % cyan

% edgeColor(2, :) = [0 1 0]; % green
% edgeColor(3, :) = [1 0 1]; % magenta

% Draw on the different meshes
for l = 2:length(AMRsol.levelArray)
    lev = AMRsol.levelArray(l);
    levDx = 0.5*lev.dx;
    
    for b = 1:length(lev.boxArray)
        thisBox = lev.boxArray(b);
    
        %lev_width = lev.xhi-lev.xlow+2*levDx;
        %lev_height = lev.yhi-lev.ylow+2*levDx;
        %lev_bottom = lev.ylow;
        fcl = meshColor(l, :);
        ecl = edgeColor(l, :);
        fcl(4) = opacity(l); % opacity
        %rectangle('Position', [thisBox.ylow thisBox.xlow  thisBox.yhi thisBox.xhi ],...
        rectangle('Position', [thisBox.xlow+levDx    thisBox.ylow  ...
            thisBox.xhi-thisBox.xlow-levDx thisBox.yhi-thisBox.ylow ],...
            'FaceColor', fcl, 'EdgeColor', ecl, 'LineWidth', 2.0);
    
    end
    
end
hold off

%axPsi.Visible = 'off';
axTemperature.Visible = 'off';

cPsi.Label.String = '\psi';
maxPsi = max(max(psiUniform));
%minPsi = min(min(psi));
%deltaPsi = maxPsi-minPsi;
%caxis([minPsi+0.01*deltaPsi maxPsi-0.01*deltaPsi]);
currentTicks = cPsi.Ticks;
newTicks = currentTicks;

newTicks = cPsi.Limits;
cPsi.Ticks = [newTicks(1) newTicks(end)];


box on;


if maxPsi < 1e-3 || maxPsi > 1e2
    formatMax = '%1.1e';
else
    formatMax = '%1.1f';
end

if newTicks(1) == 0
    formatMin = '%1.1f';
else
    formatMin = formatMax;
end

cPsi.TickLabels = {sprintf(formatMin,newTicks(1)), sprintf(formatMax,newTicks(end))};

oldPos = cPsi.Position;

if onLaptop
    cTemp.Position(2) = cTemp.Position(2)-0.02;
    cTemp.Position(4) = cTemp.Position(4)-0.02;
end

thetaColorbarPos = cTemp.Position;
%cPsi.Position = [oldPos(1) oldPos(2)-0.05 oldPos(3)-0.035 oldPos(4)];
cPsi.Position = [thetaColorbarPos(1) axisExtent(2)-0.15 thetaColorbarPos(3) thetaColorbarPos(4)];

if onLaptop
    cPsiLabelOffset = 0.7;
else
    cPsiLabelOffset = 1.2;
end
oldPos = cPsi.Label.Position;
cPsi.Label.Position = [oldPos(1) oldPos(2) + cPsiLabelOffset];

axPsi.XTick = [0 1];
axPsi.YTick = [0 1];


axTemperature.XTick = [0.02 0.98];
axTemperature.YTick = [0.02 0.98];
axTemperature.XTickLabel = {'0', '1'};
axTemperature.YTickLabel = {'0', '1'};

end
