/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2008 Orestis Malaspinas, Andrea Parmigiani, Jonas Latt
 *  Address: EPFL-STI-LIN Station 9, 1015 Lausanne
 *  E-mail: orestis.malaspinas@epfl.ch
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

#ifndef FORCED_SHAN_CHEN_COUPLING_POST_PROCESSOR_2D_H
#define FORCED_SHAN_CHEN_COUPLING_POST_PROCESSOR_2D_H

#include "core/spatiallyExtendedObject2D.h"
#include "core/postProcessing.h"
#include "core/blockLattice2D.h"


namespace olb {

/**
* Multiphysics class for coupling between different lattices.
*/

// =========================================================================//
// ===========Shan Chen coupling without wall interaction===================//
// =========================================================================//

template<typename T, template<typename U> class Lattice>
class ForcedShanChenCouplingPostProcessor2D : public LocalPostProcessor2D<T,Lattice> {
public:
    ForcedShanChenCouplingPostProcessor2D(int x0_, int x1_, int y0_, int y1_, T G_,
                                std::vector<SpatiallyExtendedObject2D*> partners_);
    virtual int extent() const { return 1; }
    virtual int extent(int whichDirection) const { return 1; }
    virtual void process(BlockLattice2D<T,Lattice>& blockLattice);
    virtual void processSubDomain(BlockLattice2D<T,Lattice>& blockLattice,
                                  int x0_, int x1_, int y0_, int y1_);
private:
    int x0, x1, y0, y1;
    T G;
    std::vector<SpatiallyExtendedObject2D*> partners;
};

template<typename T, template<typename U> class Lattice>
class ForcedShanChenCouplingGenerator2D : public LatticeCouplingGenerator2D<T,Lattice> {
public:
    ForcedShanChenCouplingGenerator2D(int x0_, int x1_, int y0_, int y1_, T G_);
    virtual PostProcessor2D<T,Lattice>* generate(std::vector<SpatiallyExtendedObject2D*> partners) const;
    virtual LatticeCouplingGenerator2D<T,Lattice>* clone() const;
private:
    T G;
};

}

#endif
