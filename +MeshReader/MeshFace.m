classdef MeshFace
    %MESHFACE A face of the mesh.
    %   An instance represent a face of the mesh, constructed by 3 nodes.
    % enabling some computation on the face, like interpolating a node of
    % a point in the face, or finding a node respecting a condition.
    %   A utilitary methods also exist for finding if a point exist in the
    % face.
    
    properties (Access=private)
        n1 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()
        n2 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()
        n3 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()
    end

    methods (Access=private, Static)
        function varargout = computeCoord2D(Ax, Ay, Bx, By, t)
            % Compute the coordinate of a point on a line.
            x = Ax .* (1-t) + Bx .* t;
            y = Ay .* (1-t) + By .* t;
            
            if nargout == 0
                error("Not enough output argument")
            elseif nargout == 1
                varargout{1} = [x',y'];
            elseif nargout == 2
                varargout{1} = x';
                varargout{2} = y';
            else
                error("Too many output arguments (%d / 2)", nargout)
            end
        end
    end

    methods (Access=protected)
        function interpolatedValue = interpolateValue(self,targetVariable, x, y)
            % Interpolate the value of 'targetVariable' at coordinate (x,y)
            arguments (Input)
                self
                targetVariable (1,1) string
                x              (1,1) double
                y              (1,1) double
            end

            U1 = self.n1.(targetVariable);
            U2 = self.n2.(targetVariable);
            U3 = self.n3.(targetVariable);

            x1 = self.n1.x_coord;  y1 = self.n1.y_coord;
            x2 = self.n2.x_coord;  y2 = self.n2.y_coord;
            x3 = self.n3.x_coord;  y3 = self.n3.y_coord;

            interpolatedValue = U1 ...
                + (U2-U1)*( (x-x1)/(x2-x1) - (x3-x1)*(y-y1)/(x2-x1)/(y3-y1) ) * ( 1 - (x3-x1)*(y2-y1)/(x2-x1)/(y3-y1) )^(-1) ...
                + (U3-U1)*( (y-y1)/(y3-y1) - (y2-y1)*(x-x1)/(y3-y1)/(x2-x1) ) * ( 1 - (y2-y1)*(x3-x1)/(y3-y1)/(x2-x1) )^(-1);
        end
    end

    methods
        function obj = MeshFace(node_1, node_2, node_3, verbose)
            %MESHFACE Construct an instance of the MeshFace class.
            %   Construct an instance of the MeshClass with 3 nodes.

            arguments (Input)
                node_1 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()
                node_2 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()
                node_3 (1,1) MeshReader.MeshNode = MeshReader.MeshNode()

                verbose (1,1) logical = false
            end

            if nargin == 0
                % default constructor
                return
            end

            obj.n1 = node_1;
            obj.n2 = node_2;
            obj.n3 = node_3;

            if verbose
                fprintf("MeshFace created with node :\n\t- %d : (%d,%d),\n \t- %d : (%d,%d),\n\t- %d : (%d,%d)\n", ...
                    obj.n1.node_number, obj.n1.x_coord, obj.n1.y_coord, ...
                    obj.n2.node_number, obj.n2.x_coord, obj.n2.y_coord, ...
                    obj.n3.node_number, obj.n3.x_coord, obj.n3.y_coord  ...
                    );
            end
        end

        
        function interpolatedNode = interpolate(self,x,y)
            %INTERPOLATE Interpolate a node on the face.
            %   Interpolate a node on the face, using finite element. Check
            % if the coordinate is in the face first.

            arguments (Input)
                self (1,1)
                x    (1,1) double
                y    (1,1) double
            end

            % Check if point in the face:
            % ---------------------------
            if ~self.contain(x,y)
                error("Impossible to interpolate a node on a point that isn't in the face !\n" + ...
                      "I've received the coordinate (%.3f,%.3f) and my nodes are definined by the coordinate " + ...
                      "n1=(%.3f,%.3f), n2=(%.3f,%.3f), n3=(%.3f,%.3f).", x,y, self.n1.x_coord,self.n1.y_coord, ...
                      self.n2.x_coord,self.n2.y_coord, self.n3.x_coord,self.n3.y_coord)
            end

            ux = self.interpolateValue("u_x",x,y);
            uy = self.interpolateValue("u_y",x,y);
            interpolatedNode = MeshReader.MeshNode(0,x,y,ux,uy);
        end

        function interpolatedNode = findNode(self,targetVariable,targetValue, options)
            %FINDNODE Interpolate the node where the variable 'targetVariable' is
            % equal to 'targetValue'.
            %   For finding the node, this method first search for the
            % nodes that are greater (1 or 2) that the target value, and
            % the node that are lower (1 or 2). It then create 'n_point' on
            % the line defined by the 2 nodes that are greater or lower,
            % and 'n_point' lines defined par the only node that is lower
            % or greater than the target value and the point defined just
            % before. It then use a dichotomie algorithme to find a point
            % on each line that respect the condition.

            arguments (Input)
                self
                targetVariable (1,1) string
                targetValue    (1,1) double
                
                options.n_point   (1,1) double {mustBePositive} = 1
                options.precision (1,1) double {mustBePositive} = 1e-12
                options.iter_max  (1,1) double {mustBePositive} = 1e3
            end

            % Check arguments:
            % ----------------
            % TODO

            % Initialization:
            % ---------------
            interpolatedNode = repmat(MeshReader.MeshNode, options.n_point);
            t = 1/(options.n_point+1) : 1/(options.n_point+1) : 1-1/(options.n_point+1);
            

            % Find p1 and p2:
            % ---------------
            inf_n1 = self.n1.(targetVariable) < targetValue;
            inf_n2 = self.n2.(targetVariable) < targetValue;
            inf_n3 = self.n3.(targetVariable) < targetValue;

            if inf_n1 == inf_n2
                % (n1,n2) | n3
                p1 = [self.n3.x_coord, self.n3.y_coord];
                p2 = MeshReader.MeshFace.computeCoord2D(self.n1.x_coord, self.n1.y_coord, self.n2.x_coord, self.n2.y_coord, t);
                if inf_n3
                    order = 1;  % U(p2)-U(p1) > 0
                else
                    order = -1; % U(p2)-U(p1) < 0
                end
            elseif inf_n2 == inf_n3
                % (n2,n3) | n1
                p1 = [self.n1.x_coord, self.n1.y_coord];
                p2 = MeshReader.MeshFace.computeCoord2D(self.n2.x_coord, self.n2.y_coord, self.n3.x_coord, self.n3.y_coord, t);
                if inf_n1
                    order = 1;  % U(p2)-U(p1) > 0
                else
                    order = -1; % U(p2)-U(p1) < 0
                end
            else % inf_n1 == inf_n3
                % (n1,n3) | n2
                p1 = [self.n2.x_coord, self.n2.y_coord];
                p2 = MeshReader.MeshFace.computeCoord2D(self.n1.x_coord, self.n1.y_coord, self.n3.x_coord, self.n3.y_coord, t);
                if inf_n2
                    order = 1;  % U(p2)-U(p1) > 0
                else
                    order = -1; % U(p2)-U(p1) < 0
                end
            end

            % Helper func:
            function U = getU(c)
                [x,y] = MeshReader.MeshFace.computeCoord2D(p1(1),p1(2),p2(ii,1),p2(ii,2),c);
                U = self.interpolateValue(targetVariable, x, y);
            end

            % Dichotomie betwenn p1 and p2:
            % -----------------------------
            for ii = 1:1:size(p2,1)
                
                % initialize dichotomie:
                c = 0.5; c1=0; c2=1;
                U = getU(c);
                diff = order*(targetValue - U);

                % dichotomie:
                n_iter = 1;
                while abs(diff) >= options.precision && n_iter <= options.iter_max

                    if diff > 0     % 'targetValue' -> U2
                        c1 = c;
                    elseif diff < 0 % 'targetValue' -> U1
                        c2 = c;
                    end

                    c = (c2+c1)/2;
                    U = getU(c);
                    diff = order*(targetValue - U);
                    n_iter = n_iter+1;

                end

                % Create node:
                coord = MeshReader.MeshFace.computeCoord2D(p1(1),p1(2),p2(ii,1),p2(ii,2),c);
                interpolatedNode(ii) = self.interpolate(coord(1),coord(2));
                %fprintf("Interpolated node x-velocity = %.6f for c=%06.6d (%.3f,%.3f)\n\n",interpolatedNode(ii).u_x,c,coord(1),coord(2))
            end

        end
    
        function rslt = contain(self,x,y)
            %CONTAIN Check if the point M=(x,y) is in the face.

            arguments (Input)
                self (1,1)
                x    (1,1) double
                y    (1,1) double
            end

            % Calcul des vecteurs MB, MC et MA
            MA = [x;y] - [self.n1.x_coord;self.n1.y_coord];
            MB = [x;y] - [self.n2.x_coord;self.n2.y_coord];
            MC = [x;y] - [self.n3.x_coord;self.n3.y_coord];
        
            % Calcul des déterminants QA, QB et QC
            QA = det([MB, MC]);
            QB = det([MC, MA]);
            QC = det([MA, MB]);
        
            % Détermination si le point M est à l'intérieur du triangle ABC
            rslt = (QA >= 0 && QB >= 0 && QC >= 0) || (QA <= 0 && QB <= 0 && QC <= 0);

        end
    
    end
end

