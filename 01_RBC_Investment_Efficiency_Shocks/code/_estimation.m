%% --- SVAR_Final_Compatible.m ---
% This is the most compatible version, removing all problematic parameters 
% that cause 'is not a recognized parameter' errors in older MATLAB releases.

clear; close all;

%% 1. Data Loading and Merging

% CRITICAL CHECK: Ensure all 3 CSVs and the .mat file are in the Current Folder
files = {'GDPC1_PCH.csv', 'GPDIC1_PCH.csv', 'PCECC96_PCH.csv'};
for i = 1:length(files)
    if ~isfile(files{i})
        error(['File not found: ', files{i}, '. Please ensure it is in the Current Folder.']);
    end
end

% Load the data
Y_data = readtable('GDPC1_PCH.csv');    
I_data = readtable('GPDIC1_PCH.csv');   
C_data = readtable('PCECC96_PCH.csv');  

% Preprocessing
Y_data.Properties.VariableNames = {'Date', 'Y_PCH'};
I_data.Properties.VariableNames = {'Date', 'I_PCH'};
C_data.Properties.VariableNames = {'Date', 'C_PCH'};

% Convert Date column
Y_data.Date = datetime(Y_data.Date);
I_data.Date = datetime(I_data.Date);
C_data.Date = datetime(C_data.Date);

% Merge Data
MergedTable = innerjoin(Y_data, I_data, 'Keys', 'Date');
MergedTable = innerjoin(MergedTable, C_data, 'Keys', 'Date');

% Extract Numerical Matrix [Y, I, C]
% Cholesky Identification Order: Output (Y) -> Investment (I) -> Consumption (C)
T = [MergedTable.Y_PCH, MergedTable.I_PCH, MergedTable.C_PCH]; 
T = rmmissing(T); 

N = size(T, 2); % Number of variables = 3
disp(['Data loaded successfully. Total observations: ', num2str(size(T, 1))]);

%% 2. SVAR Estimation (Uses Default Cholesky)

Lags = 4; 

% Create and Estimate VAR Model
Mdl = varm(N, Lags);
EstMdl = estimate(Mdl, T);

% Calculate IRF (Removing all optional parameters: 'NumPeriods', 'Multiplier')
% The IRF length (horizon) will be the default (usually 10 or 20).
IRF_Matrix = irf(EstMdl);

% Determine the actual horizon from the SVAR output
SVAR_horizon = size(IRF_Matrix, 1);
disp(['SVAR IRF calculated with a default horizon of: ', num2str(SVAR_horizon), ' quarters.']);

%% 3. Load DSGE and Plot Comparison

% Load Dynare Results
if exist('RBC_Investment_Shock.mat', 'file')
    load RBC_Investment_Shock.mat; 
    oo = oo_;
else
    error('File RBC_Investment_Shock.mat not found. Please run your Dynare .mod file first!');
end

% Variable Matching and Plot Settings
dsge_vars = {'log_Y', 'log_I', 'log_C'};
titles = {'Output (Y) Growth', 'Investment (I) Growth', 'Consumption (C) Growth'};
ShockIndex = 2; % Investment (I) is the 2nd shock in the Cholesky ordering

figure(1);
sgtitle(['SVAR vs. DSGE: Investment Shock (\epsilon_{\mu}) - Horizon: ', num2str(SVAR_horizon), ' Quarters'], 'FontSize', 14, 'FontWeight', 'bold');
lag = 0:SVAR_horizon-1;

for i = 1:N
    % --- Extract SVAR Data ---
    svar_mean = IRF_Matrix(:, i, ShockIndex);
    
    % --- Extract DSGE Data and Truncate to Match SVAR Length ---
    dsge_irf_raw = oo.irfs.([dsge_vars{i}, '_eps_mu']);
    
    % CRITICAL: Truncate DSGE data and flip sign
    dsge_irf = -dsge_irf_raw(1:SVAR_horizon); 
    
    % --- Plotting ---
    subplot(3, 1, i);
    
    % 1. DSGE Line (Red Dashed)
    plot(lag, dsge_irf, '--r', 'LineWidth', 2); hold on;
    
    % 2. SVAR Mean Line (Blue Solid)
    plot(lag, svar_mean, 'b', 'LineWidth', 1.5);
    
    % 3. Zero Reference Line
    plot(lag, zeros(size(lag)), 'k:'); 
    
    title(titles{i});
    xlabel('Quarters');
    ylabel('% Change / Deviation');
    
    if i == 1
        legend('DSGE Model', 'SVAR (Data)', 'Location', 'best');
    end
end

% Save the result
print(figure(1), 'SVAR_DSGE_Final_Result.pdf', '-dpdf', '-fillpage');
disp('Plotting complete! File saved as SVAR_DSGE_Final_Result.pdf');