clear; close all;

% --- Load the simulation results (contains all IRFs) ---
load RBC_Investment_Shock.mat; 
oo = oo_; 

% --- Settings ---
horizon = 100;
% IRFs start from period 1 (time 0 in log-linearized models)
lag = 1:horizon; 

% Define line styles to match the original image:
% TFP Shock (epsilon_A) -> Red Solid Line
% Inv. Efficiency Shock (epsilon_mu) -> Blue Dashed Line
redSolidLine  = {'-r','LineWidth',1.5};
blueDashedLine = {'--b','LineWidth',1.5};

% --- Variables to Plot and their Titles ---
variables = {'log_Y', 'log_C', 'log_I', 'log_K', 'log_N', 'log_r', 'log_W', 'log_A', 'log_mu'};
titles = {'Output (Y)', 'Consumption (C)', 'Investment (I)', 'Capital (K)', 'Labor (N)', 'Rental Rate/MPK/ (r)', 'Wage Rate(W)', 'TFP (A)', 'Inv. Shock (\mu)'};

% --- Figure Creation ---
figure(1);
sgtitle('Impulse Response Functions to a 1% Negative Shock','FontSize',14,'FontWeight','bold')

for i = 1:length(variables)
    variable_name = variables{i};
    
    subplot(3,3,i);
    
    % **CRITICAL FIX:** Plotting the negative of the IRFs to reflect a "Negative Shock"
    % 1. TFP Shock (eps_A) -> Red Solid Line
    plot(lag, -oo.irfs.([variable_name, '_eps_A'])(lag), redSolidLine{:}); 
    hold on;
    
    % 2. Inv. Efficiency Shock (eps_mu) -> Blue Dashed Line (The missing line!)
    plot(lag, -oo.irfs.([variable_name, '_eps_mu'])(lag), blueDashedLine{:});
    
    % Add zero line (Steady State)
    plot(lag, zeros(size(lag)), 'k:'); 
    
    title(titles{i});
    xlabel('Quarters');
    ylabel('% Dev. from SS');
    
    % Custom Y-label for the Rental Rate (r) 
    if strcmp(variable_name, 'log_r')
        ylabel('% Dev. from SS or ppt'); 
    end
end

% --- Legend (Shared) ---
lgd = legend('TFP Shock ($\epsilon_A$)','Inv. Efficiency Shock ($\epsilon_{\mu}$)', ...
    'Interpreter','latex', ...
    'FontSize',10, ...
    'Location','southoutside', ...
    'Orientation','horizontal');

set(lgd,'Box','off');
set(lgd,'Units','normalized');
set(lgd,'Position',[0.3 0.01 0.4 0.05]);