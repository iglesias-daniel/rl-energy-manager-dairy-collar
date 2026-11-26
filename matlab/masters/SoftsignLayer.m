classdef SoftsignLayer < nnet.layer.Layer
    % SoftsignLayer Custom implementation of Softsign activation function

    methods
        function layer = SoftsignLayer(name)
            % Constructor to set the layer name
            layer.Name = name;
            layer.Description = "Softsign activation function";
        end
        
        function Z = predict(layer, X)
            % Forward pass
            Z = X ./ (1 + abs(X));
        end
        
        function dLdX = backward(layer, X, Z, dLdZ, ~)
            % Backward pass (gradient computation)
            % Inputs:
            %   X    - Input data
            %   Z    - Output data from forward pass
            %   dLdZ - Gradients propagated from subsequent layers
            %   ~    - Placeholder for unused state
            % Output:
            %   dLdX - Gradients to propagate back

            % Derivative of Softsign: f'(x) = 1 / (1 + |x|)^2
            dLdX = dLdZ ./ ((1 + abs(X)).^2);
        end
    end
end

