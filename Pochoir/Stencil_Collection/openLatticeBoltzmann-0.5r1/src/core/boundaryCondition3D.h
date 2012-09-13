/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2007 Jonas Latt
 *  Address: Rue General Dufour 24,  1211 Geneva 4, Switzerland 
 *  E-mail: jonas.latt@gmail.com
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public 
 *  License along with this program; if not, write to the Free 
 *  Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA  02110-1301, USA.
*/

/** \file A helper for initialising 3D boundaries -- header file.  */

#ifndef BOUNDARY_CONDITION_3D_H
#define BOUNDARY_CONDITION_3D_H

#include "blockStructure3D.h"
#include "momentaOnBoundaries3D.h"
#include "boundaryPostProcessors3D.h"
#include "dynamics.h"

namespace olb {

template<typename T, template<typename U> class Lattice>
class OnLatticeBoundaryCondition3D {
public:
    virtual ~OnLatticeBoundaryCondition3D() { }

    virtual void addVelocityBoundary0N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addVelocityBoundary0P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addVelocityBoundary1N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addVelocityBoundary1P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addVelocityBoundary2N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addVelocityBoundary2P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;

    virtual void addPressureBoundary0N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addPressureBoundary0P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addPressureBoundary1N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addPressureBoundary1P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addPressureBoundary2N(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addPressureBoundary2P(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;

    virtual void addExternalVelocityEdge0NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge0NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge0PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge0PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge1NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge1NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge1PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge1PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge2NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge2NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge2PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addExternalVelocityEdge2PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;

    virtual void addInternalVelocityEdge0NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge0NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge0PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge0PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge1NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge1NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge1PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge1PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge2NN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge2NP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge2PN(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;
    virtual void addInternalVelocityEdge2PP(int x0, int x1, int y0, int y1, int z0, int z1, T omega) =0;

    virtual void addExternalVelocityCornerNNN(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerNNP(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerNPN(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerNPP(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerPNN(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerPNP(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerPPN(int x, int y, int z, T omega) =0;
    virtual void addExternalVelocityCornerPPP(int x, int y, int z, T omega) =0;

    virtual void addInternalVelocityCornerNNN(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerNNP(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerNPN(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerNPP(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerPNN(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerPNP(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerPPN(int x, int y, int z, T omega) =0;
    virtual void addInternalVelocityCornerPPP(int x, int y, int z, T omega) =0;

    virtual BlockStructure3D<T,Lattice>& getBlock() =0;
    virtual BlockStructure3D<T,Lattice> const& getBlock() const =0;
};


////////// Factory functions //////////////////////////////////////////////////

template<typename T, template<typename U> class Lattice, typename MixinDynamics>
OnLatticeBoundaryCondition3D<T,Lattice>*
    createLocalBoundaryCondition3D(BlockStructure3D<T,Lattice>& block);

template<typename T, template<typename U> class Lattice, typename MixinDynamics>
    OnLatticeBoundaryCondition3D<T,Lattice>*
        createInterpBoundaryCondition3D(BlockStructure3D<T,Lattice>& block);

template<typename T, template<typename U> class Lattice>
OnLatticeBoundaryCondition3D<T,Lattice>*
createInterpBoundaryCondition3D(BlockStructure3D<T,Lattice>& block) {
    return createInterpBoundaryCondition3D<T,Lattice,BGKdynamics<T,Lattice> >(block);
}

template<typename T, template<typename U> class Lattice>
OnLatticeBoundaryCondition3D<T,Lattice>*
createLocalBoundaryCondition3D(BlockStructure3D<T,Lattice>& block) {
    return createLocalBoundaryCondition3D<T,Lattice,RLBdynamics<T,Lattice> >(block);
}


}

#endif
