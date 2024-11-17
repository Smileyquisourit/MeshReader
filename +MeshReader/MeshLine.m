classdef MeshLine
    %MESHLINE Represent a line of the mesh.
    %   A line is an un-ordonned collection of MeshNode, but it can be
    % ordonned using differents methods.
    
    properties (Access=private)
        nodes   (:,1) MeshReader.MeshNode
    end

    properties (Dependent)

        n_point            % numel(self.nodes) where node.number ~= -1
        n_point_total      % numel(self.nodes) for all nodes
        n_point_computed   % numel(self.nodes) where node.nodenumber == 0
        n_point_mesh       % numel(self.nodes) where node.nodenumber > 0

    end

    methods % GET & SET
        function property = get.n_point(self)
            property = numel(self.nodes( [self.nodes.node_number] ~= -1 ));
        end
        function property = get.n_point_total(self)
            property = numel(self.nodes);
        end
        function property = get.n_point_computed(self)
            property = numel(self.nodes( [self.nodes.node_number] == 0 ));
        end
        function property = get.n_point_mesh(self)
            property = numel(self.nodes( [self.nodes.node_number] > 0 ));
        end
    end

    methods (Access=private)
        function ordonned_idx = ordon_nearestNeighbour(obj)

            % Construct initial point:
            [~,idx] = min([obj.nodes.x_coord]);
            ordonned_idx = zeros(1,obj.n_point);
            ordonned_idx(1) = idx;

            % Construct points to search:
            points_idx = 1:1:obj.n_point;     % Indices de tous les noeuds
            points_idx(idx) = [];             % Pop l'idx du premier noeud
            % points_test = 1:1:obj.n_point;


            % points = [obj.nodes.cart_coord];
            % points_test = [obj.nodes.cart_coord];
            % points(:,idx) = [];
            % disp("Diff between points and points test");disp(setdiff(points_test,points))

            % Search:
            % fprintf("Starting with point 1 (%+02.6f,%+02.6f) (%d)\n", obj.nodes(idx).cart_coord, idx)
            % fprintf("\tdiff with preceding: %d\n",setdiff(points_test,points_idx))
            while ~isempty(points_idx)

                % initialization:
                n = numel( ordonned_idx( ordonned_idx>0 ) );         % Nombre de points trouvé
                query_point = obj.nodes(ordonned_idx(n)).cart_coord; % Point pour lequel on cherche le suivant
                points = [obj.nodes(points_idx).cart_coord];           % Les points a evaluer

                % Compute dist:
                % x_diff = points(1,:) - query_point(1);
                % y_diff = points(2,:) - query_point(2);
                % dist_2 = sum([x_diff.^2;y_diff.^2], 1);
                dist_2 = sum( (points-query_point).^2, 1 ); % Distance entre query_point et chacun des autres points
                [~,idx] = min(dist_2);                % Idx du point le plus proche dans points
                % [~,idx] = min(sqrt(dist_2));                % Idx du point le plus proche dans points

                % Add new_point:
                ordonned_idx(n+1) = points_idx(idx);  % Idx du point (node) le plus proche
                % points_test = points_idx;             %
                points_idx(:,idx) = [];               % On enlève l'idx du point (node) trouvé des points a evaluer

                % if n <= 5
                    % disp(idx)
                    % disp(size(x_diff))
                    % disp(size(y_diff))
                    % disp(dist_2)
                    % fprintf("Find point %d (%+02.6f,%+02.6f)(%d) with dist from preceding point (%+02.6f,%+02.6f)(%d) d = %+02.6f\n", ...
                    %     n+1,obj.nodes(idx).cart_coord,idx, query_point,ordonned_idx(n),sqrt(dist_2(idx)))
                    % fprintf("\tdiff with preceding: %d\n",setdiff(points_test,points_idx))
                % end

            end
            

        end
    end
    
    methods (Access=public)

        function obj = MeshLine(n_point)
            %MESHLINE Construct an instance of the MeshLine class;
            %   Initialize an empty line. Can also intialize the line with
            % 'n_point' non initialized MeshNode.
            arguments (Input)
                n_point (1,1) double = 0
            end
            
            if n_point > 0
                obj.nodes = repmat(MeshReader.MeshNode, n_point, 1);
            end
        end
        function self = addNode(self,new_node)
            %ADDNODE Add a node to the line.
            arguments (Input)
                self     (1,1)
                new_node (1,1) MeshReader.MeshNode
            end
            
            % Add node to un-ordered list:
            idx = self.n_point+1;
            self.nodes(idx) = new_node;
        end
        
        function ord_var = sort(self,var,options)
            %SORT Sort the line using var in the order specified.
            %   Sort the line using the variables 'var' of the line's node,
            % using the order specified by 'order'. 
            %   'order' must be "ascend", "descend", "nearestNeighbour", or 
            % "none"

            arguments (Input)
                self  (1,1)
                var   (1,:) string

                options.from       (1,1) string = ""
                options.order      (1,1) string {mustBeMember(options.order,["ascend","descend","nearestNeighbour","none"])} = "ascend"
                %options.firstPoint : Only used for nearestNeighbour,
                %   indicate how the first point is determined.
            end

            % get var 'from':
            if strcmp(options.from,"")
                options.from = var(1);
            end

            % Get idx:
            if strcmp(options.order,"ascend")
                [~,idx] = sort([self.nodes.(options.from)],"ascend");
            elseif strcmp(options.order,"descend")
                [~,idx] = sort([self.nodes.(options.from)],"ascend");
            elseif strcmp(options.order,"nearestNeighbour")
                idx = self.ordon_nearestNeighbour();
            else % options.order = "none"
                idx = 1:1:self.n_point;
            end

            % Order var:
            ord_var = zeros(self.n_point,numel(var));
            for ii = 1:1:numel(var)
                ord_var(:,ii) = [self.nodes(idx).(var(ii))];
            end
        end
    
    end
end

