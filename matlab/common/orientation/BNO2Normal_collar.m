











% %{x y z}
% g = [0 -1 -1];
% m = [1 0 0];
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
% 
% % vector normal {east, north, zenith}
% z = [(A*E-D*B) (D*H-G*E) (B*G-H*A)]./div
% 
% % opuesto al vector normal
% z_p = -z