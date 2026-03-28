%% NTTHP PROOF OF CONCEPT CODE - CONVECTION %%
% Prepared by Liam Gallagher for the paper "A PARAMETRIC STUDY OF THE 
% FEASIBILITY OF A SHAPE MEMORY ALLOY TORQUE TUBE HEAT PIPE FOR THERMAL 
% TRANSPORT AND MECHANICAL ACTUATION" for the International Journal of Heat 
% and Mass Transfer

clc; clear; close all; warning('off');

%% INPUTS
%% Working Fluid
% Working fluid properties vary with temperature. You must upload a file
% with all relevant properties as they vary with temperature. Many
% properties for many working fluids can be found at the end of Jouhara, et al and Faghri

% Change path to the path of your file
waterProperties = readtable(...
    "C:\Users\13143\OneDrive - University of Dayton\Documents\Grad School\1 - CubeSat Thesis\Thesis Water HP Properties.xlsx");

% Extract columns
T           = waterProperties.Temperature;                  % [K]
T_C         = T - 273.15;                                   % [C]
rho_l       = waterProperties.Liquid_density;               % [kg/m^3]
rho_v       = waterProperties.Vapour_density;               % [kg/m^3]
k_liquid    = waterProperties.Liquid_thermal_conductivity;  % [W/(mK)]
mu_l        = waterProperties.Liquid_viscosity;             % [Pas]
mu_v        = waterProperties.Vapour_viscosity;             % [Pas]
P_vap       = waterProperties.Vapor_pressure;               % [Pa]
c_vap       = waterProperties.Vapour_specific_heat;         % [J/(kgK)]
sigma_l     = waterProperties.Liquid_surface_tension;       % [N/m]
l_vap       = waterProperties.Latent_heat;                  % [J/kg]
nu_v        = waterProperties.Vapor_specific_volume;        % [m^3/kg]
nu_l        = waterProperties.Liquid_specific_volume;       % [m^3/kg

%also:
theta       = deg2rad(60);              % Contact angle [rad]
gamma_water = 1.3;                      % Heat capacity ratio, water vapor (from "sonic limit" bookmark)
R_v         = 461;                      % Specific gas constant of water vapor [J/(kg*K)] (from "sonic limit" bookmark)
k_fluid     = 0.63;                     % Thermal conductivity of liquid water, around 40C [W/(mK)]
k_vapor     = 0.025;                    % Thermal conductivity of water vapor [W/(m*K)]
Q_r         = 45000;                    % Radial Heat Flux, [W/m^2], based on working fluid and mesh material, see Jouhara et al p. 69
T_crit      = 373.15;                   % Critical temperature (Water = 100 C)

% for the Antoine equation for the Temp/Pressure saturation curve (change for different working fluid):
A_antoine = 8.07131;
B_antoine =	1730.63;
C_antoine =	233.426;

%% Power Input, Q [W]
% Set desired heat input below.
Q = 20;

%% Ambient Temperature, T_amb [K]
% Set desired ambient temperature below (Input in Celsius as T_amb_C).
T_amb_C = 20;
T_amb = T_amb_C + 273.15;

%% Ambient Pressure, P_amb [Pa]
% Set desired ambient pressure below (Input in atm as P_amb_atm).
P_amb_atm = 1;
P_amb = P_amb_atm*101325;

%% Convective Heat Transfer Coefficient, h [W/(m^2*K)]
% Set desired heat transfer coefficient below.
% This is estimated based on cooling method at the condenser. Will the 
% condenser be cooled by still air? Forced air? Forced water? etc. Each 
% cooling method has a corresponding estimate heat transfer coefficient.
% Typical values can be found online.
h = 30;

%% Geometry Sweep - adjust as needed
num_pts = 40;

L_vary  = linspace(0.05,    1,   num_pts);
ID_vary = linspace(0.003,   0.025, num_pts);
t_vary  = linspace(0.0005,  0.01, num_pts);

% Use this range to see "microscopic" view of some valid geometries
% L_vary  = linspace(4.5,    5.5,   num_pts);
% ID_vary = linspace(0.065,   0.01, num_pts);
% t_vary  = linspace(0.0064,  0.0076, num_pts);


%% Other Parameters
% Change as needed for your particular application
k_NiTi = 8.9;

% Mesh Wick Properties (stainless steel assumed)
N_per_in        = 50;                                % Mesh # [per in]
d_wire_in       = 0.009;                             % WIRE DIAMETER/WICK THICKNESS [in
opening_in      = 0.011;                             % WIRE OPENING SIZE/WIRE SPACING [in]
numberOfWraps   = 1;                                 % # of mesh layers

d_wire          = d_wire_in*0.0254;                  % Metric conversion
t_wick          = d_wire*numberOfWraps;              % Wick Thickness [m]
t_wick_cs       = d_wire*(numberOfWraps*2);          % If a cross-section of the heat pipe is taken, the wick will line the top and bottom of the heat pipe wall, thus this represents (Wick Thickness)*2. 
N               = N_per_in/0.0254;                   % Mesh # [per m]
wire_spacing    = opening_in*0.0254;                 % Wire spacing [m]
k_wick          = 16.2;                              % Thermal conductivity of stainless steel at 20C and 100C [W/(m*K)]
phi             = deg2rad(90 - 0.5);                 % Pipe tilt angle [rad] with a 0.5 degree adverse tilt
Phi             = phi - pi/2;                        % For wick capillary term
r_pore          = wire_spacing/2;                    % Pore radius [m]
r_hw            = 0.5*wire_spacing;                  % Hydraulic radius for entrainment limit (Faghri Ch. 4)
epsilon         = 1 - ((1.05*pi*N*d_wire)/4);                                % Porosity, from Chi book (Sergey email)
K_permeab       = ((d_wire^2)*(epsilon^3))/(122*((1 - epsilon)^2));          % From Chi book (Sergey email)
k_wick_eff      = epsilon * k_fluid + (1 - epsilon) * k_wick;

% Resistive load
sigma_f     = 210*10^6;            % Detwin finish stress of Nitinol [Pa]
g           = 9.81;                % Gravity [m/s^2]

% Properties of Nitinol
E              = 30*10^9;          % Young's Modulus [Pa], MARTENSITE (used for conservative values)
mu             = 0.3;              % Poisson's Ratio
sigma_y        = 700*10^6;         % Yield Stress [Pa]
gamma_tr       = 0.04;             % Transformation Strain, 4%
twist_goal     = 60; % deg

% Buckling FOS
B_FOS = 4; % Due to imperfections that may start to from before actual buckling effects

%% RESULTS
% Preallocation
L_all = [];
ID_all = [];
t_all = [];

Sigma_all = [];
tau_star_all = [];
P_star_all = [];
B_all = [];

%% 3D Map of Valid Geometries
% Initialize arrays to store results
valid_geoms = [];
fail_flags = [];

% Loop through all combinations
for i = 1:length(L_vary)
    for j = 1:length(ID_vary)
        for k = 1:length(t_vary)

            % Geometry parameters:
            L = L_vary(i);
            ID = ID_vary(j);
            t = t_vary(k);

            OD = ID + 2 * t;
            OR = OD/2;
            IR = ID/2;

            L_hp = L;
            L_evap = 0.0254*2; % 2in
            L_cond = 0.0254*1; % 1in
            L_adiabatic = L - (L_evap + L_cond);
            L_eff = L_adiabatic + (L_evap/2) + (L_cond/2);
            L_twist = L - (2*0.0254);

            OD_wick = ID;
            ID_wick = OD_wick - t_wick_cs;
            r_w_outer_passfail = ID/2;
            r_w_inner = r_w_outer_passfail - t_wick_cs;
            A_vs = pi * r_w_inner^2;                  % Vapor space area
            A_wick = pi*(r_w_outer_passfail^2 - r_w_inner^2);
            A_pipe_inner = pi*IR^2;
            A_NiTi = (pi*OR^2) - (A_pipe_inner);
            A_evap = pi*OD*L_evap;
            A_cond = pi*OD*L_cond;

            % Thermal resistances used to calculate important temperatures
            % and pressures. NOTE that if thermal grease (or similar) is
            % used on the outer surface of the pipe, this must be
            % represented as a resistance in the circuit as well
            R_NiTi_evap = log(OD/ID)/(2*pi*L_evap*k_NiTi);
            R_NiTi_cond = log(OD/ID)/(2*pi*L_cond*k_NiTi);
            R_wick_evap = log(OD_wick/ID_wick)/(2*pi*L_evap*k_wick_eff);
            R_wick_cond = log(OD_wick/ID_wick)/(2*pi*L_cond*k_wick_eff);
            R_vs = 0; % Assumed for T_vap > 35 C
            R_ext = 1/(h*A_cond);

            T_evap = T_amb + Q * (R_NiTi_evap + R_wick_evap + R_vs + R_wick_cond + R_NiTi_cond + R_ext);
            T_sat = T_evap - Q * (R_NiTi_evap + R_wick_evap);
            T_wall = T_sat + Q * R_wick_evap; % The temperature between the NiTi wall and the wick at the evaporator (Faghri Ch. 4)
            T_cond = T_amb + Q * R_ext;

            T_sat_C = T_sat - 273.15; % convert to C
            P_exp_mmHg = 10^(A_antoine - (B_antoine/(C_antoine + T_sat_C)));
            P_exp = P_exp_mmHg*133.3223684; % convert to Pa

            if T_sat_C < 35
                warning('T_{sat} , 35C! R_{vs} = 0 assumption may be inaccurate!')
            end

            l_vap_interp        = interp1(T, l_vap, T_sat, 'linear', 'extrap');
            sigma_l_interp      = interp1(T, sigma_l, T_sat, 'linear', 'extrap');
            rho_l_interp        = interp1(T, rho_l, T_sat, 'linear', 'extrap');
            rho_v_interp        = interp1(T, rho_v, T_sat, 'linear', 'extrap');
            mu_l_interp         = interp1(T, mu_l, T_sat, 'linear', 'extrap');
            mu_v_interp         = interp1(T, mu_v, T_sat, 'linear', 'extrap');
            P_vap_interp        = interp1(T, P_vap, T_sat, 'linear', 'extrap');


            % other important parameters
            m_dot = Q / l_vap_interp;  % Vapor mass flow rate [kg/s]

            DeltaT_crit = T_wall - T_sat; % Faghri, Ch. 4
            k_eff  = (Q * L_eff) / (A_pipe_inner * DeltaT_crit);

            twist = gamma_tr*(L_twist/OR);
            J = pi*(OD^4 - ID^4)/32; % Polar moment of inertia [m^4]
            Torque = (sigma_f*J)/OR; % This is the minimum applied torque needed to detwin the material for thick-walled cylinders in [N*m]. OD is used for conservative results.

            % Structural limits
            P_i = P_exp;
            P_o = P_amb;
            Pressure_diff = P_i - P_o;
            sigma_h = ((P_i*IR^2 - P_o*OR^2)/(OR^2 - IR^2) + (IR^2*OR^2*(P_i - P_o))/(IR^2*(OR^2 - IR^2)));    % Hoop stress (Lame's equations)
            sigma_r = (P_i*IR^2 - P_o*OR^2)/(OR^2 - IR^2) - (IR^2*OR^2*(P_i - P_o))/(IR^2*(OR^2 - IR^2));      % Radial stress (Lame's equations)
            sigma_a = ((P_i*IR^2) - (P_o*OR^2))/(OR^2 - IR^2);                                                 % Axial/longitudinal stress (Lame's equations)
            tau = Torque*OR/J;                                                                                 % Torsional stress from an applied torque for a thick-walled cylinder
            %vonMises = sqrt(sigma_h^2 + sigma_a^2 - sigma_h*sigma_a + 3*tau^2);
            vonMises = sqrt(0.5*((sigma_h - sigma_a)^2 + (sigma_a - sigma_r)^2 + (sigma_r - sigma_h)^2) + 3*tau^2);
            Sigma = vonMises / sigma_y;

            detwin_passfail = vonMises / sigma_f;

            % Buckling Analysis (Source: NASA document "Buckling of Thin-Walled Circular Cylinders")
            % Buckling: Critical Pressure
            P_long = (0.9*E/(4*(1 - mu^2)))*(t/OR)^3;
            P_short = (0.855*0.75*E/((1 - mu^2)^0.75))*(1/((OR/t)^(5/2)*(L/OR)));
            P_crit = max(P_short, P_long);
            % Buckling: Critical Torsional Shear Stress
            Z = ((L/OR)^2)*(OR/t)*sqrt(1 - mu^2);       % Batdorf parameter to ensure use of relevant equations for specific geometry
            y = 0.586;                                  % Use conservatively low gamma value here
                if y*Z > 78*((OR/t)^2)*(1 - mu^2)
                    tau_crit = ((0.8*E)/(3*sqrt(2)*((1 - mu^2)^(3/4))))*((t/OR)^(3/2));     % Use y = 0.8
                elseif y*Z > 50 && y*Z < 78*((OR/t)^2)*(1 - mu^2)
                    tau_crit = (0.747*(0.586^(3/4))*E)/(((OR/t)^(5/4))*(L/OR)^(1/2));       % Use y = 0.586
                else
                    tau_crit = (0.747*(0.586^(3/4))*E)/(((OR/t)^(5/4))*(L/OR)^(1/2));       % Use y = 0.586
                end

            % Buckling: Combine Loads
            tau_star = tau / tau_crit;
            P_star = P_exp / P_crit;
            B = B_FOS*(tau_star + P_star);

            % Twist angle
            twist_ratio = rad2deg(gamma_tr*(L/(OD/2))) / twist_goal;

            % Capillary pumping ability
            P_laminar   = (mu_l_interp * Q * L_eff) / (rho_l_interp * l_vap_interp * A_wick * K_permeab); % FROM FAGHRI TOP OF PAGE 227
            P_vapor = ((8 * mu_v_interp * m_dot * L_eff) / (rho_v_interp * pi * r_w_inner^4));
            P_gravity   = rho_l_interp * g * L_eff * sin(Phi); % FROM HEAT PIPES REAY TEXT
            
            P_cap   = P_laminar + P_vapor + abs(P_gravity);           % Meniscus pressure [Pa]
            DeltaP_cap  = (2 * sigma_l_interp / r_pore) * cos(theta); % Max capillary head [Pa]
            capPressure   = DeltaP_cap - P_cap;

            % Heat pipe limits
            capillary   = Q/(((sigma_l_interp*rho_l_interp*l_vap_interp)/mu_l_interp)*((K_permeab*A_wick)/L_eff)*((2/r_pore) - ((rho_l_interp*g*L_hp*cos(phi)/sigma_l_interp))));
            viscous     = Q/((pi*(r_w_inner^4)*l_vap_interp*rho_v_interp*P_vap_interp)/(12*mu_v_interp*L_eff));
            sonic       = Q/(A_vs * rho_v_interp* l_vap_interp* sqrt((gamma_water * R_v * T_sat)/(2*(gamma_water + 1))));
            entrainment = Q/(A_vs * l_vap_interp * sqrt((sigma_l_interp * rho_v_interp)/(2*r_hw)));
            boiling     = Q/((2*pi*L_evap*k_eff*DeltaT_crit)/log(IR/r_w_inner));
            condenser   = Q/((T_cond - T_amb)/R_ext);

            % --- Apply pass/fail criteria ---
            twist_ok = twist_ratio > 1;
            detwin_ok = detwin_passfail > 1;
            sigma_ok = Sigma < 1;
            B_ok = B < 1;
            %capPressure_ok = capPressure > 0;
            capPressure_ok = capillary < 1;
            capillary_ok = capillary < 1; % Two methods for evaluating the capillary limit are included. This is likely the more trustworthy method.
            viscous_ok = viscous < 1;
            sonic_ok = sonic < 1;
            entrain_ok = entrainment < 1;
            boil_ok = boiling < 1;
            cond_ok = condenser < 1;

            all_ok = twist_ok && detwin_ok && sigma_ok && B_ok && capPressure_ok && capillary_ok && viscous_ok && sonic_ok && entrain_ok && boil_ok && cond_ok;

            if all_ok
                valid_geoms(end+1, :) = [L, ID, t];
            else
                fail_flags(end+1, :) = [L, ID, t, twist_ok, detwin_ok, sigma_ok, B_ok, capPressure_ok, capillary_ok, viscous_ok, sonic_ok, entrain_ok, boil_ok, cond_ok];
            end

            % Store variables for plotting
            L_all(end+1) = L;
            ID_all(end+1) = ID;
            t_all(end+1) = t;
            Sigma_all(end+1) = Sigma;
            tau_star_all(end+1) = tau_star;
            P_star_all(end+1) = P_star;
            B_all(end+1) = B;
        end
    end
end

%% Failure Analysis Diagnostic
% This will help you understand which limits are most strict for your simulated NTTHP

fprintf('\n--- FAILURE ANALYSIS REPORT ---\n');
fprintf('Total combinations tested: %d\n', size(fail_flags, 1));

% Define the labels for the flags in the order they were saved
labels = {'Twist', 'Detwin', 'Sigma', 'Buckling', 'Cap Pressure', ...
          'Capillary', 'Viscous', 'Sonic', 'Entrainment', 'Boiling', 'Condenser'};

% The flags start at column 4 in fail_flags
% Calculate how many times each flag was TRUE=1
pass_counts = sum(fail_flags(:, 4:end), 1);
pass_percentages = (pass_counts / size(fail_flags, 1)) * 100;

% Print report to console
for m = 1:length(labels)
    fprintf('%s Limit: %.2f%% of designs passed\n', labels{m}, pass_percentages(m));
end

% Create a bar chart to visualize the bottleneck
figure('Name', 'Why did the design fail?', 'Color', 'w');
bar(pass_percentages, 'FaceColor', [0.8 0.2 0.2]);
set(gca, 'XTickLabel', labels, 'XTick', 1:length(labels));
xtickangle(45);
ylabel('Pass Rate (%)');
title('Bottleneck Analysis: Which limit is too strict?');
grid on;
ylim([0 100]);

% Find the absolute killers
killers = labels(pass_percentages == 0);
if ~isempty(killers)
    msg = sprintf('The following criteria had a 0%% pass rate: %s. Check your physics/inputs for these.', strjoin(killers, ', '));
    warning(msg);
end

%% 3D Plot
if isempty(valid_geoms) 
    error('No valid geometries found'); 
end

K_passfail = convhull(valid_geoms(:,1), valid_geoms(:,2), valid_geoms(:,3));

figure;
trisurf(K_passfail, valid_geoms(:,1), valid_geoms(:,2), valid_geoms(:,3), ...
    'FaceColor', [0.5 0.8 0.5], 'FaceAlpha', 0.4, 'EdgeColor', 'none')
xlabel('L [m]', 'FontSize', 12)
ylabel('d_i [m]', 'FontSize', 12)
zlabel('t [m]', 'FontSize', 12)
% title('Valid Design Region (All Limits Passed)')
hold on
scatter3(valid_geoms(:,1), valid_geoms(:,2), valid_geoms(:,3), 30, 'g', 'filled')
% if ~isempty(fail_flags)
%    scatter3(fail_flags(:,1), fail_flags(:,2), fail_flags(:,3), 20, 'r', 'filled')
% end
legend('Valid Region', 'Passed Points', 'Failed Points', 'FontSize', 12)

set(gca, 'YDir', 'reverse');
view(3)

%% 2D Versions
%% Data Extraction
L_2d  = valid_geoms(:,1);
ID_2d = valid_geoms(:,2);
t_2d  = valid_geoms(:,3);

% Create a figure sized for a journal column (roughly 1200x400 pixels)
figure('Color', 'w', 'Position', [100, 100, 1200, 350]);

% --- Plot 1: t vs ID ---
subplot(1, 3, 1);
k1 = boundary(ID_2d, t_2d, 0.1); % 0.1 is shrink factor (adjust as needed)
fill(ID_2d(k1), t_2d(k1), [0.8 0.9 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5); 
hold on;
scatter(ID_2d, t_2d, 15, 'g', 'filled', 'MarkerFaceAlpha', 0.6);
xlabel('d_i [m]', 'FontSize', 12); ylabel('t [m]', 'FontSize', 12);
% title('(a) Design Space: t vs ID');
grid on; set(gca, 'XDir', 'reverse'); % Matching your original YDir reverse logic

% --- Plot 2: t vs L ---
subplot(1, 3, 2);
k2 = boundary(L_2d, t_2d, 0.1);
fill(L_2d(k2), t_2d(k2), [0.8 0.9 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on;
scatter(L_2d, t_2d, 15, 'g', 'filled', 'MarkerFaceAlpha', 0.6);
xlabel('L [m]', 'FontSize', 12); ylabel('t [m]', 'FontSize', 12);
% title('(b) Design Space: t vs L');
grid on;

% --- Plot 3: ID vs L ---
subplot(1, 3, 3);
k3 = boundary(L_2d, ID_2d, 0.1);
fill(L_2d(k3), ID_2d(k3), [0.8 0.9 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
hold on;
scatter(L_2d, ID_2d, 15, 'g', 'filled', 'MarkerFaceAlpha', 0.6);
xlabel('L [m]', 'FontSize', 12); ylabel('d_i [m]', 'FontSize', 12);
% title('(c) Design Space: ID vs L');
grid on;

% Universal Journal Formatting
set(findall(gcf,'-property','FontSize'),'FontSize', 12, 'FontName', 'Arial');
% sgtitle('Projections of Valid Design Region', 'FontSize', 12, 'FontWeight', 'bold');


% %% Point Checker -- test any geometry to see if it falls within the 3D plot's valid region
% % Enter the values you want to test:
% L_test  = 0.3;       % [m]
% ID_test = 0.0055;    % [m]
% t_test  = 0.00125;   % [m]
% 
% % Create a Triangulation of your valid points
% % This creates a "mesh" that fills the valid volume
% pts = unique(valid_geoms, 'rows');
% dt = delaunayTriangulation(pts(:,1), pts(:,2), pts(:,3));
% 
% % Use tsearchn to see if the point lies within any of the tetrahedrons
% % If tid is not NaN, the point is inside the valid volume
% point_to_check = [L_test, ID_test, t_test];
% tid = tsearchn(pts, dt.ConnectivityList, point_to_check);
% is_valid = ~isnan(tid);
% 
% % Report results
% fprintf('\n--- TEST POINT ANALYSIS ---\n');
% if is_valid
%     fprintf('RESULT: [L=%.4f, ID=%.4f, t=%.4f] is VALID.\n', L_test, ID_test, t_test);
%     p_color = 'c'; % Cyan for valid
% else
%     fprintf('RESULT: [L=%.4f, ID=%.4f, t=%.4f] is INVALID.\n', L_test, ID_test, t_test);
%     p_color = 'm'; % Magenta for invalid
% end
% 
% % Update the 3D plot
% figure(gcf); 
% hold on;
% plot3(L_test, ID_test, t_test, 'p', 'MarkerSize', 15, ...
%     'MarkerFaceColor', p_color, 'MarkerEdgeColor', 'k', 'LineWidth', 1);
% title('3D Map of Valid Geometries');
% hold off;

%% MISC
%% Heat pipe limits map

%% Sigma and B

% target_L = L_vary(round(end/2));
% target_t = t_vary(round(end/2));
% 
% % Create a logical index for the specific L and t we want to look at
% % Since we stored them linearly, we can recreate the logic:
% [L_grid, ID_grid, t_grid] = meshgrid(L_vary, ID_vary, t_vary);
% % Note: meshgrid ordering can be tricky, it's safer to just filter the 1D arrays:
% 
% % 1. Identify which points in our big "all" arrays match the specific L and t
% idx = (L_all == target_L) & (t_all == target_t);
% 
% figure('Color', 'w', 'Name', 'Sensitivity Analysis');
% 
% % 2. Plot Sigma (Stress Ratio)
% yyaxis right
% % Use ID_all(idx) so the X and Y vectors are the same length
% plot(ID_all(idx), Sigma_all(idx), '-o', 'Color', 'r', 'LineWidth', 1.5); 
% ylabel('Stress Ratio (\sigma / \sigma_y)');
% ylim([0 2])
% hold on;
% 
% % 3. Plot B (Buckling Ratio)
% yyaxis left
% ylim([0 2])
% plot(ID_all(idx), B_all(idx), '-s', 'Color', 'b', 'LineWidth', 1.5);
% ylabel('Buckling Ratio (B)');
% hold on;
% yline(1, 'm--', 'Buckling Limit', 'LineWidth', 2);
% 
% xlabel('Inner Diameter (ID) [m]');
% title(sprintf('Effect of ID on Stress and Buckling\n(Fixed L = %.2f m, t = %.4f m)', target_L, target_t));
% grid on;
% legend('Sigma Ratio', 'Buckling Ratio', 'Threshold', 'Location', 'best');
% ylim([0 2])


%% B map
% % Prepare Data for Plotting
% % Flatten the 3D arrays into 1D vectors.
% tau_flat = tau_star_all(:);
% P_flat   = P_star_all(:);
% B_flat   = B_all(:);
% 
% % Restrict to a domain between 0 and 2
% idx = (tau_flat >= 0) & (tau_flat <= 2) & (P_flat >= 0) & (P_flat <= 2);
% tau_plot = tau_flat(idx);
% P_plot   = P_flat(idx);
% B_plot   = B_flat(idx);
% 
% % Interpolate Scattered Data onto a Regular Grid
% tau_lin = linspace(0, 2, 200);  % 200 points from 0 to 2 for tau*
% P_lin   = linspace(0, 2, 200);  % 200 points from 0 to 2 for P*
% [TAU, P_grid] = meshgrid(tau_lin, P_lin);
% 
% % Interpolate using griddata. Here we use a 'cubic' interpolation.
% B_interp = griddata(tau_plot, P_plot, B_plot, TAU, P_grid, 'cubic');
% 
% % Plot the results
% figure;
% contourf(TAU, P_grid, B_interp, 20, 'LineStyle','none');  % 20 contour levels
% colorbar;
% xlim([0 2]);
% ylim([0 2]);
% xlabel('\tau^*');
% ylabel('P^*');
% title('Contoured Map of B Values in the (\tau^*, P^*) Space');
% 
% % Create a colormap with many points (e.g., 256) using jet
% caxis([0 4]);
% ncolors = 256;
% cmap = jet(ncolors);
% 
% % Force the last color to be pure red
% cmap(end,:) = [1, 0, 0];
% colormap(cmap);
% 
% % Overlay a black line where B == 1
% hold on;
% [~, hC] = contour(TAU, P_grid, B_interp, [1 1], 'k', 'LineWidth', 3);
% legend(hC, 'B = 1');
% hold off;