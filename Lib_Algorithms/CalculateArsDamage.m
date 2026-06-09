%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

function ars_damage = CalculateArsDamage(elementData_MDL,r_localDamage)
    
    ars_damage = elementData_MDL(:, 2).^(r_localDamage);

end
