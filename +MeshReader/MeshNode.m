classdef MeshNode < handle
    %MESHNODE A node of the mesh.
    %   An instance represent a point of the mesh, enabling some 
    % computation like the polar coordinate. When the node is constructed
    % from a MeshFile, it's node_number correspond to it's actual node
    % number, and when it's computed with an interpolation, it should have
    % a node_number equal to 0. When the instance isn't initialized, it
    % must have a node_number equal to -1.

    properties (GetAccess=public)
        node_number (1,1) double = -1
        x_coord     (1,1) double = 0
        y_coord     (1,1) double = 0
        u_x         (1,1) double = 0
        u_y         (1,1) double = 0
    end

    properties (Dependent)
        r_coord (1,1) double
        t_coord (1,1) double
        u_r     (1,1) double
        u_t     (1,1) double

        cart_coord (2,1) double
    end

    methods % GET
        function property = get.r_coord(self)
            property = sqrt( self.x_coord^2 + self.y_coord^2 );
        end
        function property = get.t_coord(self)
            property = atan2(self.y_coord, self.x_coord);
        end
        function property = get.u_r(self)
            property = self.u_x*cos(self.t_coord) + self.u_y*sin(self.t_coord);
        end
        function property = get.u_t(self)
            property = -self.u_x*sin(self.t_coord) + self.u_y*cos(self.t_coord);
        end
    
        function property = get.cart_coord(self)
            property = [self.x_coord; self.y_coord];
        end
    end

    methods (Access=public)
        function obj = MeshNode(n,x,y,ux,uy)

            arguments (Input)
                n  (1,1) double = -1
                x  (1,1) double = 0
                y  (1,1) double = 0
                ux (1,1) double = 0
                uy (1,1) double = 0
            end

            if nargin == 0
                % Default constructor
                return
            end

            obj.node_number = n;
            obj.x_coord = x;
            obj.y_coord = y;
            obj.u_x = ux;
            obj.u_y = uy;
        end
    end
    
end