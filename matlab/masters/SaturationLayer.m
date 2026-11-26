classdef SaturationLayer < nnet.layer.Layer
    % SaturationLayer Custom implementation of a linear saturation activation function

    methods
        function layer = SaturationLayer(name)
            % Constructor to set the layer name
            layer.Name = name;
            layer.Description = "Linear saturation activation function";
        end
        
        function Z = predict(layer, X)
            % Forward pass
            Z = max(min(X, 1), -1); % Saturate values to [-1, 1]
        end
        
        function dLdX = backward(layer, X, Z, dLdZ, ~)
            % Backward pass (gradient computation)
            % The gradient is 1 in the linear region, and 0 in the saturated regions
            dLdX = dLdZ .* (X > -1 & X < 1); % Pass gradients only in the linear region
        end
    end
end

%layers = [
%    featureInputLayer((size(selection,1) + 2), 'Name', %'state')
%    fullyConnectedLayer(hidden_unit, 'Name', 'fc1')
%    reluLayer('Name', 'relu1')
%    fullyConnectedLayer(hidden_unit, 'Name', 'fc2')
%    reluLayer('Name', 'relu2')
%    fullyConnectedLayer(3, 'Name', 'action')
%    SaturationLayer('saturation') % Reemplaza relu3 con la %nueva capa
%    ];


