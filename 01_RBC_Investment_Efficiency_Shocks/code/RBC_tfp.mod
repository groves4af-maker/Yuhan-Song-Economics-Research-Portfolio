// Dynare code for the Real Business Cycle (RBC) model with ONLY TFP Shock.

// Endogenous Variables
// Variables: Y C K N I r W A  (8 Levels) + log_Y...log_A (8 Logs) = 16 variables
var Y C K N I r W A 
    log_Y log_C log_I log_K log_N log_r log_W log_A; 
 
// Exogenous Variables (Shocks)
varexo eps_A;

// Parameters and Calibration
parameters beta alpha delta varphi rho_A 
           A_ss 
           r_ss K_Y_ss C_Y_ss b N_ss Y_ss K_ss I_ss C_ss W_ss; 

// Structural Parameters (from baseline RBC)
beta=0.99;    // Household discount factor (quarterly)
alpha=0.33;   // Capital share in production
delta=0.025;  // Capital depreciation rate (quarterly)
varphi=1;     // Inverse of Frisch labor supply elasticity

// Shock Process Parameters 
rho_A=0.98;   // Persistence of TFP shock

// Steady-State (SS) Calibration:
// Normalize steady-state TFP and Investment Efficiency (implicitly) to 1
A_ss=1;


// 1. Steady-state rental rate (r_ss) from Euler Equation (SS-1)
r_ss = (1/beta) - 1 + delta;

// 2. Steady-state Capital-to-Output ratio (K_Y_ss) from Profit Maximization (SS-2)
K_Y_ss = alpha / (r_ss + delta);

// 3. Steady-state Wage (W_ss) from Profit Maximization (SS-3)
W_ss = (1-alpha)*A_ss*(K_Y_ss)^(alpha/(1-alpha));

// 4. Steady-state Labor (N_ss) from Labor Supply (SS-4) - We normalize to N_ss=1/3
N_ss = 0.3333333333333333; // Normalized to 1/3

// 5. Steady-state Output (Y_ss) from Production Function (SS-5)
Y_ss = A_ss*(K_Y_ss)^(alpha/(1-alpha)) * N_ss; 

// 6. Steady-state Capital (K_ss)
K_ss = K_Y_ss * Y_ss;

// 7. Steady-state Investment (I_ss) from Capital Accumulation (SS-7)
I_ss = delta*K_ss;

// 8. Steady-state Consumption (C_ss) from Resource Constraint (SS-6)
C_ss = Y_ss - I_ss; 

// 9. Steady-state Consumption-to-Output ratio (C_Y_ss)
C_Y_ss = C_ss/Y_ss;

// 10. Steady-state Labor Disutility Weight (b) from Labor Supply (SS-4)
b = W_ss / (C_ss * (N_ss^varphi));



// -------------------------------------------------------------
// MODEL BLOCK
// -------------------------------------------------------------

model;

// 1. Household Euler Equation (Intertemporal Choice)
1/C = beta*(1/C(+1))*(r(+1) + 1 - delta);

// 2. Household Labor Supply (Intratemporal Choice)
b*N^varphi*C = W;

// 3. Firm Capital Demand (Profit Maximization)
r = alpha*A*(K(-1)^(alpha-1))*(N^(1-alpha));

// 4. Firm Labor Demand (Profit Maximization)
W = (1-alpha)*A*(K(-1)^alpha)*(N^(-alpha));

// 5. Aggregate Resource Constraint
Y = C + I;

// 6. Production Function
Y = A*(K(-1)^alpha)*(N^(1-alpha));

// 7. Capital Accumulation
K = (1-delta)*K(-1) + I; 

// 8. TFP Shock Process (A_t)
A = (1-rho_A)*A_ss + rho_A*A(-1) + eps_A;


//-------------------------------------------------------------
// LOG DEVIATIONS FROM STEADY STATE 
//-------------------------------------------------------------

// All variables expressed in percent deviations from steady-state (e.g., 1% = 1),
// except for the rental rate r which is annualized percentage point deviation.

log_Y = 100*(Y-Y_ss)/Y_ss;
log_C = 100*(C-C_ss)/C_ss;
log_I = 100*(I-I_ss)/I_ss;
log_K = 100*(K-K_ss)/K_ss;
log_N = 100*(N-N_ss)/N_ss;
log_W = 100*(W-W_ss)/W_ss;
log_A = 100*(A-A_ss)/A_ss;

// log_r: Annualized percentage point deviation
log_r = 400*(r-r_ss); 

end; 


// -------------------------------------------------------------
// Steady State Block
// -------------------------------------------------------------
initval;
Y = Y_ss;
C = C_ss;
K = K_ss;
N = N_ss; 
I = I_ss; 
r = r_ss;
W = W_ss;
A = A_ss;


log_Y = 0;
log_C = 0;
log_I = 0;
log_K = 0;
log_N = 0;
log_r = 0;
log_W = 0;
log_A = 0;
end;

// Calculate the steady state
steady;

// Check the stability of the model
check;


// -------------------------------------------------------------
// SIMULATION AND OUTPUT
// -------------------------------------------------------------

shocks;
// Variance of TFP shock (eps_A)
var eps_A; stderr 0.01; 
end;

// Stochastic Simulation. 
stoch_simul(order=1, irf=0, nograph) log_Y log_C log_I log_K log_N log_r log_W log_A;