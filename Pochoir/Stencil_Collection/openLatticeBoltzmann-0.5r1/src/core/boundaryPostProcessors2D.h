/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2006, 2007 Jonas Latt
 *  Address: Rue General Dufour 24,  1211 Geneva 4, Switzerland 
 *  E-mail: jonas.latt@gmail.com
 *
 *  Generic version of the collision, which modifies the particle 
 *  distribution functions, by Orestis Malaspinas.
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

#ifndef FD_BOUNDARIES_2D_H
#define FD_BOUNDARIES_2D_H

#include "postProcessing.h"
#include "momentaOnBoundaries.h"
#include "blockLattice2D.h"

namespace olb {

/**
* This class computes the skordos BC
* on a flat wall in 2D but with a limited number of terms added to the
* equilibrium distributions (i.e. only the Q_i : Pi term)
*/
template<typename T, template<typename U> class Lattice, int direction, int orientation>
class StraightFdBoundaryProcessor2D : public LocalPostProcessor2D<T,Lattice>
{
public:
    StraightFdBoundaryProcessor2D(int x0_, int x1_, int y0_, int y1_);
    virtual int extent() const { return 1; }
    virtual int extent(int whichDirection) const { return 1; }
    virtual void process(BlockLattice2D<T,Lattice>& blockLattice);
    virtual void processSubDomain ( BlockLattice2D<T,Lattice>& blockLattice,
                                   int x0_, int x1_, int y0_, int y1_ );
private:
    template<int deriveDirection>
    void interpolateGradients (
            BlockLattice2D<T,Lattice> const& blockLattice,
            T velDeriv[Lattice<T>::d], int iX, int iY ) const;
private:
    int x0, x1, y0, y1;
};

template<typename T, template<typename U> class Lattice, int direction, int orientation>
class StraightFdBoundaryProcessorGenerator2D : public PostProcessorGenerator2D<T,Lattice>
{
public:
    StraightFdBoundaryProcessorGenerator2D(int x0_, int x1_, int y0_, int y1_);
    virtual PostProcessor2D<T,Lattice>* generate() const;
    virtual PostProcessorGenerator2D<T,Lattice>*  clone() const;
};

/**
* This class computes the skordos BC in 2D on a convex
* corner but with a limited number of terms added to the
* equilibrium distributions (i.e. only the Q_i : Pi term)
*/
template<typename T, template<typename U> class Lattice, int xNormal,int yNormal>
class OuterVelocityCornerProcessor2D : public LocalPostProcessor2D<T, Lattice> {
public:
    OuterVelocityCornerProcessor2D(int x_, int y_);
    virtual int extent() const { return 2; }
    virtual int extent(int whichDirection) const { return 2; }
    virtual void process(BlockLattice2D<T,Lattice>& blockLattice);
    virtual void processSubDomain(BlockLattice2D<T,Lattice>& blockLattice,
                                  int x0_,int x1_,int y0_,int y1_ );
private:
    int x, y;
};

template<typename T, template<typename U> class Lattice, int xNormal,int yNormal>
class OuterVelocityCornerProcessorGenerator2D : public PostProcessorGenerator2D<T, Lattice>
{
public:
    OuterVelocityCornerProcessorGenerator2D(int x_, int y_);
    virtual PostProcessor2D<T,Lattice>* generate() const;
    virtual PostProcessorGenerator2D<T,Lattice>*  clone() const;
};

}

#endif
