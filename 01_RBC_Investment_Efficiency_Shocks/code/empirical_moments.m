% -------------------------------------------------------------------
% EMPIRICAL MOMENTS CALCULATION FOR Q7
% This script loads the raw US data, converts it to quarterly, 
% calculates log-levels, and computes the required standard deviations 
% and correlations for comparison with the Dynare theoretical moments.
% -------------------------------------------------------------------

% 1. Load Data
try
    % Note: PCEC96 is monthly, GDPC1 and GPDIC1 are quarterly.
    % We will use the 'textscan' function to handle the data load.
    
    % Read GDP (GDPC1: Quarterly)
    fid_y = fopen('GDPC1.csv', 'r');
    data_y = textscan(fid_y, '%s %f', 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid_y);
    dates_y = data_y{1};
    Y = data_y{2};

    % Read Investment (GPDIC1: Quarterly)
    fid_i = fopen('GPDIC1.csv', 'r');
    data_i = textscan(fid_i, '%s %f', 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid_i);
    dates_i = data_i{1};
    I = data_i{2};

    % Read Consumption (PCEC96: Monthly - Needs Downsampling to Quarterly)
    fid_c = fopen('PCEC96.csv', 'r');
    data_c = textscan(fid_c, '%s %f', 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid_c);
    dates_c = data_c{1};
    C_monthly = data_c{2};

catch ME
    disp('Error loading CSV files. Please ensure all three files (GDPC1.csv, GPDIC1.csv, PCEC96.csv) are in the current MATLAB folder.');
    rethrow(ME);
end

% 2. Align Data and Convert Monthly C to Quarterly
% Find common start/end dates for quarterly data (1947Q1 - latest)
% Assuming monthly C data is aligned quarterly by taking the last month of the quarter
% We will use the quarterly dates from Y and I to filter C

% Find common quarterly dates (first month of the quarter)
quarterly_dates = dates_y(cellfun(@(x) x(6:7) == '01' || x(6:7) == '04' || x(6:7) == '07' || x(6:7) == '10', dates_y));

% For Consumption, aggregate monthly data to quarterly by averaging or taking the last month. 
% We'll use the last month of the quarter for simplicity, assuming the monthly data 
% is not seasonally adjusted to be quarterly. Since GDPC1 is quarterly, we should 
% assume PCEC96 should be at the same frequency. The safer approach is to align 
% the dates based on the common quarterly frequency of GDPC1/GPDIC1.
% Let's assume the user's GDPC1/GPDIC1 data is already quarterly frequency 
% (e.g., Q1, Q2, Q3, Q4).

% Since PCEC96 is monthly and GDPC1/GPDIC1 are quarterly, we must align by
% date. For this assignment, we use the simpler method: extract C for the same
% dates as Y and I (which are quarterly). Since the raw CSVs show Y and I
% starting 1947-01-01, we will resample C on 01-01, 04-01, 07-01, 10-01.

C = [];
for i = 1:length(dates_y)
    current_date = dates_y{i};
    % Find the corresponding monthly C value for this quarter's start date
    idx_c = find(strcmp(dates_c, current_date));
    if ~isempty(idx_c)
        C = [C; C_monthly(idx_c)];
    else
        % If C data is not available for a Y/I date, truncate other series.
        Y(i) = NaN;
        I(i) = NaN;
    end
end
% Remove NaNs due to truncation/mismatched start/end
common_idx = ~isnan(Y) & ~isnan(I) & ~isnan(C);
Y = Y(common_idx);
I = I(common_idx);
C = C(common_idx);


% 3. Convert to Log Levels and Compute Standard Deviation and Correlations
log_Y = log(Y);
log_C = log(C);
log_I = log(I);

% Compute standard deviations
std_Y = std(log_Y);
std_C = std(log_C);
std_I = std(log_I);

% Compute correlations
M = [log_Y, log_C, log_I];
R = corrcoef(M); % Correlation matrix

corr_C_Y = R(1, 2);
corr_I_Y = R(1, 3);

% 4. Format and Display Empirical Moments
fprintf('\n-----------------------------------------------\n');
fprintf('  EMPIRICAL MOMENTS (Log Levels, No HP Filter) \n');
fprintf('-----------------------------------------------\n');
fprintf('Variable | Std. Dev. (%%) | Relative Std. Dev. | Corr. with Y \n');
fprintf('---------------------------------------------------\n');
fprintf('log_Y    | %11.4f | %18.4f | %12.4f \n', std_Y * 100, 1.0000, 1.0000);
fprintf('log_C    | %11.4f | %18.4f | %12.4f \n', std_C * 100, std_C / std_Y, corr_C_Y);
fprintf('log_I    | %11.4f | %18.4f | %12.4f \n', std_I * 100, std_I / std_Y, corr_I_Y);
fprintf('---------------------------------------------------\n');

% Save variables for easy comparison in the next step
save('empirical_moments_q7.mat', 'std_Y', 'std_C', 'std_I', 'corr_C_Y', 'corr_I_Y');

disp('Empirical moments calculation complete. Use these values for comparison in Q7.');