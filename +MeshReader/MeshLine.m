classdef MeshLine < handle
    %MESHLINE Represent a line of the mesh.
    %   A line is an ordonned collection of nodes, which are a set of point
    % that can be ordonned.


    % methode pour compter le nombre de noeud non-initialiser
    % Ajouter un nouveau noeud a la fin des noeud initialiser
    
    properties (Access=public)
        nodes (:,1) MeshReader.MeshNode
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
    
    methods (Access=public)
        function obj = MeshLine(n_point)
            %MESHLINE Construct an instance of the MeshLine class;
            %   Initialize an empty line. Can also intialize the line with
            % 'n_point' non initialized MeshNode.
            arguments (Input)
                n_point (1,1) double = 0
            end
            
            if n_point > 0
                obj.nodes = repmat(MeshNode, n_point, 1);
            end
        end
        
        function addNode(self,new_node)
            %ADDNODE Add a node to the line.
            arguments (Input)
                self     (1,1)
                new_node (1,1) MeshReader.MeshNode
            end
            
            self.nodes(self.n_point+1) = new_node;
        end
        function sort(self,var,order)
            %SORT Sort the line using var in the order specified.
            %   Sort the line using the variable 'var' of the line's node,
            % using the order specified by 'order'. 
            %   'order' must be "ascend" or "descend"

            arguments (Input)
                self  (1,1)
                var   (1,1) string
                order (1,1) string {mustBeMember(order,["ascend","descend"])} = "ascend"
            end

            [~,idx] = sort([self.nodes.(var)],order);
            self.nodes = self.nodes(idx);
        end
    end
end

