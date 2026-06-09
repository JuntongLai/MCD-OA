%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

% This is the fuction for initial ODEs based on a regulatory network:
% J. Lai and D. Lacroix, "Mathematical modelling of inflammatory process and obesity in osteoarthritis", PLOS ONE, vol. 20, no. 6, p. e0323258, Jun. 2025, doi: 10.1371/journal.pone.0323258.
function dydt = ODEsOfInflammation(t, y, ...
    ars)

    % Parameters in production of pro-inflammatory cytokine
    C_0 = ars.C_0;    % Natural pro-inflammatory production rate
    C_1 = ars.C_1;    % Pro-inflammatory cytokine production rate driven by pro-inflammatory cytokine
    C_2 = ars.C_2;
    C_3 = ars.C_3;    % Pro-inflammatory cytokine production rate driven by adipokine
    C_4 = ars.C_4;
    C_5 = ars.C_5;    % Pro-inflammatory cytokine production rate driven by Fibronectin-fragments
    C_6 = ars.C_6;
    C_7 = ars.C_7;
    D_1 = ars.D_1;    % Clearance rate of pro-inflammatory cytokine
    
    % Parameters in production of anti-inflammatory cytokine
    C_8 = ars.C_8;    % Anti-inflammatory cytokine production rate driven by pro-inflammatory cytokine
    C_9 = ars.C_9;  % Pro-inflammatory cytokine concentration whose capability of driving anti-inflammatory cytokine is half of maximum
    C_10 = ars.C_10;    % Anti-inflammatory cytokine production rate driven by Fibronectin-fragments
    C_11 = ars.C_11;  % Fibronectin-fragments concentration whose capability of driving anti-inflammatory cytokine is half of maximum
    D_2 = ars.D_2;

    % Parameters in production of adipokine
    C_12 = ars.C_12;     % Natural MMPs production rate
    C_13 = ars.C_13;    % MMPs production rate driven by pro-inflammatory cytokine
    C_14 = ars.C_14;  % Pro-inflammatory cytokine concentration whose capability of driving MMPs is half of maximum
    C_15 = ars.C_15;    % MMPs production rate driven by adipokines
    C_16 = ars.C_16;  % Adipokine concentration whose capability of driving MMPs is half of maximum
    C_17 = ars.C_17;  % Anti-inflammatory cytokine concentration whose capability of inhibiting MMPs is half of maximum
    D_3 = ars.D_3;  % Clearance rate of MMPs

    % Parameters in production of adipokine
    C_18 = ars.C_18;      % Natural adipokine production rate
    C_19 = ars.C_19;      % Production rate of adipokine driven by BMI
    C_20 = ars.C_20;    % adipokine concentration whose capability of driving adipokine is half of maximum, which depends on exercise level
    D_4 = ars.D_4;    % Clearance rate of adipokine
    paranutrition = ars.paranutrition; % Nutrition term
    fBMI = ars.fBMI;            % BMI level
    
    % Parameters in production of Fibronectin-fragments
    C_21 = ars.C_21;
    C_22 = ars.C_22;      % Damage level
    D_5 = ars.D_5;    % Clearance rate of Fibronectin-fragments

    % Hill coefficient
    n = ars.n;

    % Exercise coefficient
    nex = ars.nex;

    % Output from Nondimentional ODEs
    dydt = zeros(5,1);

    % Timescaling
    TS = 1;

    dydt(1) = ((C_0 + C_1.*(y(1).^n)./((C_2).^n+y(1).^n) + C_3.*(y(4).^n)./((C_4).^n+y(4).^n) + C_5.*(y(5).^n)./((C_6).^n+y(5).^n)).*((C_7.^n)./(C_7.^n+y(2).^n)) - D_1.*y(1))./TS; %dPIC/dt   y(1) is PIC
    dydt(2) = (C_8.*((y(1).^n))./(C_9.^n+(y(1).^n)) + C_10.*(y(5).^n)./(C_11.^n+y(5).^n) - D_2.*y(2))./TS;      %dAIC/dt
    dydt(3) = ((C_12 + C_13.*(y(1).^n)./(C_14.^n+y(1).^n) + C_15.*(y(4).^n)./(C_16.^n+y(4).^n)).*(C_17.^n)./(C_17.^n+y(2).^n) - D_3.*y(3))./TS;   %dMMPs/dt
    dydt(4) = (C_18 + (C_19.*fBMI.*paranutrition).*(C_20.^nex)./(C_20.^nex+y(4).^nex) - D_4.*y(4))./TS;    %dA/dt
    dydt(5) = (C_21.*y(3) + C_22 - D_5.*y(5))./TS; %dFnFs/dt;

end