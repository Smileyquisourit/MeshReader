 # CFD Analysis Tool for FLUENT Student Version

This project provides tools to analyze the results of a numerical simulation (CFD) using the student version of FLUENT. It includes functionalities to extract the boundary layer from the simulation data.

The goal of this project was to extract and plot the necessary data to analyse the boundary layer for a flow around a cylindre. A framework was developped to work the CFD results, re-construct a mesh with the available data, and perfom search and analysis on the data.

## Project Structure

The project is organized as follows:
- The `+MeshReader` folder contains the source code of the differents class developped to represent the mesh.
- The `+utils` folder contains a function that print a progress bar, as the process can be long.
- The `Demo` folder contains the result data of 2 simulations and 2 script that extract and plot the boundary layer and the velocity profil around the cylinder wall.

## Simulation data

The data contained in the `Demo/data` folder is of 2 simulations:
- *Case1* is the result of a steady simulation, with a x-velocity of 200 m.s^(-1).
- *Case2* is the result of a transient simulation, with a x-velocity of 200 m.s^(-1).

Both simulations use the same geometry and same mesh in Fluent.

## MeshReader

The class developped are the following:
- `Mesh.m`: Main class to handle mesh data.
- `MeshNode.m`: Class to handle mesh nodes.
- `MeshFace.m`: Class to handle mesh faces.
- `MeshLine.m`: Class to handle mesh lines.

It can be imported with the following syntax:
```matlab
import MeshReader.*
```

The differents class have differents purposes, described as follow:

### Mesh

The Mesh class represents the results of a CFD simulation. It reads and processes data from a file containing the results of a CFD simulation, and create a triangular mesh using Matlab `delaunnay` function. This class provides various methods for traversing the faces of this mesh, as well as a method for searching for faces that contain specific points.
You can create a Mesh by giving it the path to the file containing the simulation results. You can also specified a name for the name:
``` matlab
mesh = MeshReader.Mesh(file, "name","mesh_name")
```

### MeshNode

The MeshNode class represents a node of the mesh. An instance represents a point of the mesh, and can compute the polar coordinate of the node. 
It isn't recommended to create a MeshNode directly, but should be created with methods from the Mesh class and the MeshFace class.

### MeshFace

The MeshFace class represents a face of the mesh, constructed by 3 nodes. It enables computations on the face, such as interpolating a node of a point in the face or finding a node respecting a condition. When interpolating a node on the face, wee use Finite Element method. When finding nodes that respect a certain condition, we use dichotomy for going through the face.

Like for MeshNode, it isn't recommended to create directly a MeshFace, but to use method from the Mesh class.

### MeshLine

The MeshLine class represents a line of the mesh. A line is an un-ordered collection of nodes, which are a set of points of then mesh with computable properties (like velocity or polar coordinate). The nodes are saved in a un-ordoned list, but the user can sort them using different methods:
- *ascend* sort the nodes by the ascending order from the variable specified
- *descend* sort the nodes by the ascending order from the variable specified
- *nearestNeighbourt* try to sort the nodes by starting from the node with the lowest x coordinate, and find the following node with the lowest euclidian distance.
- *none* doesn't sort the nodes, so their are in the order in wich they were found

For creating a MeshLine, use the following syntax:
```matlab
line = MeshReader.MeshLine();  % create an empty line
line = MeshReader.MeshLine(n); % create a line with n un-initialyse node.
```
For obtaining the sorted nodes, use the following syntaxe:
```matlab
sorted_data = line.sort(["var1","var2"],"from","var1","order","ascend")
```
The first argument is the wanted variables, the *from* argument is the variable on wich to base the sorting (by default the first of the wanted variable), and the *order* argument is the order in wich you want to sort the nodes.