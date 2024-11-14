classdef Mesh < handle
    %MESH Represent the results of a CFD simulation.
    %   This class is designed to read and process data from a file 
    % containing the results of a Computational Fluid Dynamics (CFD) 
    % simulation. When an instance of this class is created, it loads the 
    % data into a table and generates a mesh using MATLAB's 'delaunay' 
    % function. The class provides various methods for traversing the faces 
    % of this mesh, as well as a method for searching for faces that 
    % contain specific points. This allows for efficient analysis and 
    % visualization of the simulation results.
    %
    %   This class expect to find the following data in the result file of
    % the CFD simulation:
    %   - nodenumber
    %   - x-coordinate 
    %   - y-coordinate
    %   - x-velocity
    %   - y-velocity
    %
    %   Additionally, this class provides a method for extracting data from 
    % the faces of the mesh. This can be done in one of two ways: either by 
    % creating an instance of a separate 'face' class, or by returning the 
    % data as a table. The first method may take longer to execute, as it 
    % involves creating and initializing a new object. However, the second 
    % method is faster and provides better performance, making it a 
    % suitable choice for large datasets.
    
    properties (Access=private)
        file        (1,1) string
        data        (:,:) table = table();
        DT          (:,3) double

        EXPECTED_COL_NAMES = {'nodenumber','x-coordinate','y-coordinate','x-velocity','y-velocity'};
    end

    properties (Access=public)
        name (1,1) string = ""
    end

    properties (Dependent)

        nb_faces (1,1) double
        nb_nodes (1,1) double

    end

    methods % GET & SET

        function property = get.nb_faces(self)
            property = size(self.DT,1);
        end
        function property = get.nb_nodes(self)
            property = size(self.data,1);
        end

    end
    
    methods (Access=public)

        function obj = Mesh(file, verbose, options)
            %MESH Construct an instance of the Mesh class.
            %   Construct the instance by reading the file into a table,
            % and creating a triangular mesh using the delaunnay function.
            arguments (Input)
                file    (1,1) string = ""
                verbose (1,1) logical = true

                options.name (1,1) string = file
            end

            % Default constructor:
            if nargin == 0
                return
            end

            if verbose
                fprintf("Creating Mesh...");
            end

            % Read file:
            if ~isfile(file)
                error("Mesh:BadFile","The file '%s' can't be found !",file)
            end
            obj.file = file;
            obj.data = readtable(file,'VariableNamingRule','preserve');
            
            % Check data:
            if ~all(ismember(obj.EXPECTED_COL_NAMES,obj.data.Properties.VariableNames))
                not_found_variables = obj.EXPECTED_COL_NAMES(~(ismember(obj.EXPECTED_COL_NAMES,obj.data.Properties.VariableNames)));
                error("Mesh:NotExpectedColumns","The following variables were'nt found in the file: %s !", strjoin(not_found_variables,', '))
            end

            % Create mesh:
            obj.DT = delaunay(obj.data.("x-coordinate"), obj.data.("y-coordinate"));
            obj.name = options.name;

            if verbose
                fprintf("\tdone !\n")
                fprintf("Mesh created with %d nodes and %d faces.\n",obj.nb_nodes,obj.nb_faces)
                for ii = 1:1:numel(obj.data.Properties.VariableNames)
                    if obj.data.Properties.VariableNames{ii} == "nodenumber"
                        continue
                    end
                    fprintf("\t%s : min=%+.3f, max=%+.3f\n", ...
                        obj.data.Properties.VariableNames{ii}, ...
                        min(obj.data.(obj.data.Properties.VariableNames{ii})), ...
                        max(obj.data.(obj.data.Properties.VariableNames{ii})) ...
                        )
                end
            end
        end
        
        function face = face(self,i)
            %FACE_DATA The face i.
            % Get the face indexed by i.

            arguments (Input)
                self (1,1)
                i    (1,1) double
            end

            % Check idx:
            if i <= 0 && i <= self.nb_faces
                error("Idx must be between 1 and %d, instead I've received %d", self.nb_faces, i);
            end

            % Construct face:
            idx = self.DT(i,:);
            node_1 = self.node(idx(1));
            node_2 = self.node(idx(2));
            node_3 = self.node(idx(3));
            face = MeshReader.MeshFace(node_1,node_2,node_3);
        end
        function node = node(self,i)
            %NODE The node i.
            % Get the node indexed by i.

            arguments (Input)
                self (1,1)
                i    (1,1) double
            end

            % Check idx:
            if i <= 0 && i <= self.nb_faces
                error("Idx must be between 1 and %d, instead I've received %d", self.nb_nodes, i);
            end

            % Construct node:
            node_data = self.node_data(i);
            node = MeshReader.MeshNode( ...
                node_data.nodenumber,       ...
                node_data.("x-coordinate"), ...
                node_data.("y-coordinate"), ...
                node_data.("x-velocity"),   ...
                node_data.("y-velocity")    ...
                );
        end

        function face_data = face_data(self,i)
            %FACE_DATA The data of the face i.
            % Get the data of the face indexed by i.

            arguments (Input)
                self (1,1)
                i    (1,1) double
            end

            % Check idx:
            if i <= 0 && i <= self.nb_faces
                error("Idx must be between 1 and %d, instead I've received %d", self.nb_faces, i);
            end

            % Get face data
            nodes_idx = self.DT(i,:);
            face_data = self.data(nodes_idx,:);
        end
        function node_data = node_data(self,i)
            %NODE_DATA The data of the node i.
            % Get the data of the node indexed by i.

            arguments (Input)
                self (1,1)
                i    (1,1) double
            end

            % Check idx:
            if i <= 0 && i <= self.nb_faces
                error("Idx must be between 1 and %d, instead I've received %d", self.nb_nodes, i);
            end

            % Get face data
            node_data = self.data(i,:);
        end
    
        function m = min(self,var)
            %MIN Return the minimum value of 'var'
            m = min(self.data.(var));
        end
        function m = max(self,var)
            %MIN Return the maximum value of 'var'
            m = max(self.data.(var));
        end
    end
end

