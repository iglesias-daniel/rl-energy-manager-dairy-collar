function z = normal_vector(g,m)
%NORMAL_VECTOR Summary of this function goes here
% Por Daniel Iglesias 2024

%{x y z}
% g = [gx gy gz];
% m = [mx my mz];

%magnitud de los vectores
m_m = vecnorm(m,2,2);
m_g = vecnorm(g,2,2);

%coeficientes
A = m(:,1)./m_m;
B = m(:,2)./m_m;
C = m(:,3)./m_m;
D = -g(:,1)./m_g;
E = -g(:,2)./m_g;
F = -g(:,3)./m_g;
G = (m(:,3).*g(:,2)-m(:,2).*g(:,3))./(m_g.*m_m);
H = (m(:,1).*g(:,3)-m(:,3).*g(:,1))./(m_g.*m_m);
I = (m(:,2).*g(:,1)-m(:,1).*g(:,2))./(m_g.*m_m);

div = (A.*E.*I+B.*F.*G+C.*D.*H)-(G.*E.*C+H.*F.*A+I.*D.*B);

% vector normal {east, north, zenith}
z = [(A.*E-D.*B) (D.*H-G.*E) (B.*G-H.*A)]./div;
z = z./vecnorm(z,2,2);

% opuesto al vector normal
%z_p = -z

end

% function z = normal_vector(g,m)
% %NORMAL_VECTOR Summary of this function goes here
% 
% %{x y z}
% % g = [gx gy gz];
% % m = [mx my mz];
% 
% %magnitud de los vectores
% m_m = norm(m);
% m_g = norm(g);
% 
% %coeficientes
% A = m(1)/m_m;
% B = m(2)/m_m;
% C = m(3)/m_m;
% D = -g(1)/m_g;
% E = -g(2)/m_g;
% F = -g(3)/m_g;
% G = (m(3)*g(2)-m(2)*g(3))/(m_g*m_m);
% H = (m(1)*g(3)-m(3)*g(1))/(m_g*m_m);
% I = (m(2)*g(1)-m(1)*g(2))/(m_g*m_m);
% 
% div = (A*E*I+B*F*G+C*D*H)-(G*E*C+H*F*A+I*D*B);
% 
% % vector normal {east, north, zenith}
% z = [(A*E-D*B) (D*H-G*E) (B*G-H*A)]./div;
% 
% % opuesto al vector normal
% %z_p = -z
% 
% end
