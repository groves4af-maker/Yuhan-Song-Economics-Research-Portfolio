
// Endogenous Variables)
var Y C K N I r W A mu 
    log_Y log_C log_I log_K log_N log_r log_W log_A log_mu; 
 
// Exogenous Variables 
varexo eps_A eps_mu;

// Parameters and Calibration
parameters beta alpha delta varphi rho_A rho_mu 
           A_ss mu_ss 
           r_ss K_Y_ss C_Y_ss b N_ss Y_ss K_ss I_ss C_ss W_ss; 
// Structural Parameters (from baseline RBC)
beta=0.99;    // Household discount factor (quarterly)
alpha=0.33;   // Capital share in production
delta=0.025;  // Capital depreciation rate (quarterly)
varphi=1;     // Inverse of Frisch labor supply elasticity

// Shock Process Parameters
rho_A=0.98;   // Persistence of TFP shock
rho_mu=0.98;  // Persistence of Investment Efficiency shock


// Steady-State (SS) Calibration:
// Normalize steady-state TFP and Investment Efficiency to 1
A_ss=1;
mu_ss=1; 

// 1. Steady-state rental rate (r_ss) from Euler Equation (SS-1)
r_ss = 1/beta - (1-delta); 

// 2. Steady-state Capital/Output ratio (K_Y_ss) from Firm FOC (SS-3)
K_Y_ss = alpha / r_ss; 

// 3. Steady-state Consumption/Output ratio (C_Y_ss) from Resource Constraint (SS-5)
C_Y_ss = 1 - delta * K_Y_ss; 

// 4. Steady-state Labor (N_ss) normalization and calculation of parameter 'b'
// We normalize steady-state labor to N_ss = 1/3 (a common RBC calibration choice)
N_ss = 1/3;
// 'b' is calculated from the labor supply condition (b*N^phi = W/C) in SS
b = (1-alpha) / (C_Y_ss * N_ss^(1+varphi)); 

// 5. Normalise Y_ss and calculate other SS values
Y_ss = 1;
K_ss = K_Y_ss * Y_ss;    
I_ss = delta * K_ss;     
C_ss = C_Y_ss * Y_ss;    
W_ss = (1-alpha) * Y_ss / N_ss; 


model;


// 1. Euler Equation 
1/C = beta * (mu/C(1)) * (r(1) + (1-delta)/mu(1));

// 2. Labor Supply/Intratemporal Condition 
b*N^varphi = W/C;

// 3. Production Function 
Y = A * K(-1)^alpha * N^(1-alpha);

// 4. Capital Accumulation 
K = (1-delta)*K(-1) + mu*I;

// 5. Resource Constraint (GE.7, solved for I)
Y = C + I; 

// 6. Capital Demand / MPK 
r = alpha * A * K(-1)^(alpha-1) * N^(1-alpha);

// 7. Labor Demand / MPL 
W = (1-alpha) * A * K(-1)^alpha * N^(-alpha);


// 8. TFP Shock Process  - Linearised form for A around A_ss=1 (ln(A_ss)=0)
log(A) = rho_A * log(A(-1)) + eps_A; 

// 9. Investment Shock Process  - Linearised form for mu around mu_ss=1 (ln(mu_ss)=0)
log(mu) = rho_mu * log(mu(-1)) + eps_mu;


// All variables expressed in percent deviations from steady-state (e.g., 1% = 1),
// except for the rental rate r which is annualized percentage point deviation.

log_Y = 100*(Y-Y_ss)/Y_ss;
log_C = 100*(C-C_ss)/C_ss;
log_I = 100*(I-I_ss)/I_ss;
log_K = 100*(K-K_ss)/K_ss;
log_N = 100*(N-N_ss)/N_ss;
log_W = 100*(W-W_ss)/W_ss;
log_A = 100*(A-A_ss)/A_ss;
log_mu = 100*(mu-mu_ss)/mu_ss;

// log_r: Annualized percentage point deviation
log_r = 400*(r-r_ss); 

end; 


// Steady State Block
initval;
Y = Y_ss;
C = C_ss;
K = K_ss;
N = N_ss; 
I = I_ss; 
r = r_ss;
W = W_ss;
A = A_ss;
mu = mu_ss;

log_Y = 0;
log_C = 0;
log_I = 0;
log_K = 0;
log_N = 0;
log_r = 0;
log_W = 0;
log_A = 0;
log_mu = 0;
end;

// Calculate the steady state
steady;

// Check the real part of the Jacobian eigenvalues
check;

// Define Shocks
shocks;
// Shocks are defined here to be 1% of the steady-state mean for the IRF.
// A 1% drop in A or mu means a negative shock of -0.01 in the log-linearized model.
var eps_A; stderr 0.01; 
var eps_mu; stderr 0.01;
end;

// Stochastic Simulation and Impulse Response Functions (IRF)
// irf=100 for 100 periods, nograph to suppress automatic plotting
// The log-linearized variables are used for plotting to satisfy the request.
stoch_simul(order=1, irf=100, nograph) log_Y log_C log_I log_K log_N log_r log_W log_A log_mu; 

// Save the results for subsequent analysis (Question 7)
save('RBC_Investment_Shock.mat', 'oo_', 'M_', 'options_');