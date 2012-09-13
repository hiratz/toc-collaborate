/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2006, 2007, 2008 Jonas Latt
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

/** \file
 * Dynamics for a generic 3D block lattice view -- generic implementation.
 */
#ifndef BLOCK_LATTICE_VIEW_3D_HH
#define BLOCK_LATTICE_VIEW_3D_HH

#include "blockLatticeView3D.h"
#include "cell.h"
#include "dataAnalysis3D.h"

namespace olb {

////////////////////// Class BlockLatticeView3D /////////////////////////

template<typename T, template<typename U> class Lattice>
BlockLatticeView3D<T,Lattice>::BlockLatticeView3D(BlockStructure3D<T,Lattice>& originalLattice_)
    : originalLattice(&originalLattice_),
      x0(0), y0(0), z0(0),
      nx( originalLattice->getNx() ),
      ny( originalLattice->getNy() ),
      nz( originalLattice->getNz() ),
      dataAnalysis( new DataAnalysis3D<T,Lattice>(*this) )
{ }

template<typename T, template<typename U> class Lattice>
BlockLatticeView3D<T,Lattice>::BlockLatticeView3D (
    BlockStructure3D<T,Lattice>& originalLattice_,
    int x0_, int x1_, int y0_, int y1_, int z0_, int z1_ )
    : originalLattice(&originalLattice_),
      x0(x0_), y0(y0_), z0(z0_),
      nx(x1_-x0_+1),
      ny(y1_-y0_+1),
      nz(z1_-z0_+1),
      dataAnalysis( new DataAnalysis3D<T,Lattice>(*this) )
{
    OLB_PRECONDITION(x0 < originalLattice->getNx());
    OLB_PRECONDITION(nx >= 1);
    OLB_PRECONDITION(y0 < originalLattice->getNy());
    OLB_PRECONDITION(ny >= 1);
    OLB_PRECONDITION(z0 < originalLattice->getNz());
    OLB_PRECONDITION(nz >= 1);
}

template<typename T, template<typename U> class Lattice>
BlockLatticeView3D<T,Lattice>::~BlockLatticeView3D()
{
    delete dataAnalysis;
}

template<typename T, template<typename U> class Lattice>
BlockLatticeView3D<T,Lattice>::BlockLatticeView3D(BlockLatticeView3D<T,Lattice> const& rhs)
    : originalLattice(rhs.originalLattice),
      x0(rhs.x0), y0(rhs.y0), z0(rhs.z0),
      nx(rhs.nx), ny(rhs.ny), nz(rhs.nz),
      dataAnalysis( new DataAnalysis3D<T,Lattice>(*this) )
{ }

template<typename T, template<typename U> class Lattice>
BlockLatticeView3D<T,Lattice>& BlockLatticeView3D<T,Lattice>::operator= (
    BlockLatticeView3D<T,Lattice> const& rhs )
{
    BlockLatticeView3D<T,Lattice> tmp(rhs);
    swap(tmp);
    return *this;
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::swap (
    BlockLatticeView3D<T,Lattice>& rhs)
{
    std::swap(nx, rhs.nx);
    std::swap(ny, rhs.ny);
    std::swap(nz, rhs.nz);
    std::swap(x0, rhs.x0);
    std::swap(y0, rhs.y0);
    std::swap(z0, rhs.z0);
    std::swap(originalLattice, rhs.originalLattice);
    std::swap(dataAnalysis, rhs.dataAnalysis);
}

template<typename T, template<typename U> class Lattice>
Cell<T,Lattice>& BlockLatticeView3D<T,Lattice>::get(int iX, int iY, int iZ) {
    OLB_PRECONDITION(iX<nx);
    OLB_PRECONDITION(iY<ny);
    OLB_PRECONDITION(iZ<nz);
    return originalLattice->get(iX+x0, iY+y0, iZ+z0);
}

template<typename T, template<typename U> class Lattice>
Cell<T,Lattice> const& BlockLatticeView3D<T,Lattice>::get (
        int iX, int iY, int iZ ) const
{
    OLB_PRECONDITION(iX<nx);
    OLB_PRECONDITION(iY<ny);
    OLB_PRECONDITION(iZ<nz);
    return originalLattice->get(iX+x0, iY+y0, iZ+z0);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::initialize() {
    originalLattice->initialize();
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::defineDynamics (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_,
        Dynamics<T,Lattice>* dynamics )
{
    originalLattice->defineDynamics( x0_+x0, x1_+x0,
                                     y0_+y0, y1_+y0,
                                     z0_+z0, z1_+z0,
                                     dynamics );
                                    
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::defineDynamics (
        int iX, int iY, int iZ, Dynamics<T,Lattice>* dynamics )
{
    originalLattice->defineDynamics( iX+x0, iY+y0, iZ+z0, dynamics );
}


template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::specifyStatisticsStatus (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_, bool status )
{
    originalLattice->specifyStatisticsStatus (
                              x0_+x0, x1_+x0,
                              y0_+y0, y1_+y0,
                              z0_+z0, z1_+z0,
                              status );
                                 
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::collide (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_ )
{
    originalLattice->collide( x0_+x0, x1_+x0,
                              y0_+y0, y1_+y0,
                              z0_+z0, z1_+z0 );
                                 
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::collide() {
    originalLattice->collide( x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::staticCollide (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_,
        TensorFieldBase3D<T,3> const& u)
{
    originalLattice->staticCollide( x0_+x0, x1_+x0,
                                    y0_+y0, y1_+y0,
                                    z0_+z0, z1_+z0, u);
                                 
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::staticCollide (
         TensorFieldBase3D<T,3> const& u )
{
    originalLattice->staticCollide( x0, x0+nx-1, y0, y0+ny-1,
                                    z0, z0+nz-1, u);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::stream(int x0_, int x1_, int y0_, int y1_, int z0_, int z1_) {
    originalLattice->stream( x0_+x0, x1_+x0,
                             y0_+y0, y1_+y0,
                             z0_+z0, z1_+z0 );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::stream(bool periodic) {
    OLB_PRECONDITION(!periodic);
    originalLattice->stream( x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1);
    postProcess();
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::collideAndStream (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_ )
{
    originalLattice->collideAndStream( x0_+x0, x1_+x0,
                                       y0_+y0, y1_+y0,
                                       z0_+z0, z1_+z0 );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::collideAndStream(bool periodic) {
    OLB_PRECONDITION(!periodic);
    originalLattice->collideAndStream(x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1);
    postProcess();
}

template<typename T, template<typename U> class Lattice>
T BlockLatticeView3D<T,Lattice>::computeAverageDensity (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_ ) const
{
    return originalLattice->computeAverageDensity( x0_+x0, x1_+x0,
                                                   y0_+y0, y1_+y0,
                                                   z0_+z0, z1_+z0 );
}

template<typename T, template<typename U> class Lattice>
T BlockLatticeView3D<T,Lattice>::computeAverageDensity() const {
    return originalLattice->computeAverageDensity (
            x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1 );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::stripeOffDensityOffset (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_, T offset )
{
    originalLattice->stripeOffDensityOffset( x0_+x0, x1_+x0,
                                             y0_+y0, y1_+y0,
                                             z0_+z0, z1_+z0, offset);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::stripeOffDensityOffset(T offset) {
    originalLattice->stripeOffDensityOffset (
            x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1, offset);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::forAll (
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_,
        WriteCellFunctional<T,Lattice> const& application )
{
    originalLattice->forAll( x0_+x0, x1_+x0,
                             y0_+y0, y1_+y0,
                             z0_+z0, z1_+z0, application);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::forAll(WriteCellFunctional<T,Lattice> const& application) {
    originalLattice->forAll (
            x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1, application );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::addPostProcessor (
        PostProcessorGenerator3D<T,Lattice> const& ppGen )
{
    PostProcessorGenerator3D<T,Lattice>* shiftedGen = ppGen.clone();
    shiftedGen->shift(x0,y0,z0);
    originalLattice->addPostProcessor(*shiftedGen);
    delete shiftedGen;
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::resetPostProcessors() {
    originalLattice->resetPostProcessors();
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::postProcess() {
    originalLattice -> postProcess(x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::postProcess(
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_)
{
    originalLattice -> postProcess( x0_+x0, x1_+x0, y0_+y0, y1_+y0, z0_+z0, z1_+z0 );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::addLatticeCoupling (
         LatticeCouplingGenerator3D<T,Lattice> const& lcGen,
         std::vector<SpatiallyExtendedObject3D*> partners )
{
    LatticeCouplingGenerator3D<T,Lattice>* shiftedGen = lcGen.clone();
    shiftedGen->shift(x0,y0,z0);
    originalLattice->addLatticeCoupling(*shiftedGen, partners);
    delete shiftedGen;
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::executeCoupling() {
    originalLattice -> executeCoupling(x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1);
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::executeCoupling(
        int x0_, int x1_, int y0_, int y1_, int z0_, int z1_)
{
    originalLattice -> executeCoupling( x0_+x0, x1_+x0, y0_+y0, y1_+y0, z0_+z0, z1_+z0 );
}

template<typename T, template<typename U> class Lattice>
void BlockLatticeView3D<T,Lattice>::
         subscribeReductions(Reductor<T>& reductor)
{
    originalLattice -> subscribeReductions(reductor);
}

template<typename T, template<typename U> class Lattice>
LatticeStatistics<T>& BlockLatticeView3D<T,Lattice>::
    getStatistics()
{
    return originalLattice->getStatistics();
}

template<typename T, template<typename U> class Lattice>
LatticeStatistics<T> const& BlockLatticeView3D<T,Lattice>::getStatistics() const
{
    return originalLattice->getStatistics();
}

template<typename T, template<typename U> class Lattice>
DataAnalysisBase3D<T,Lattice> const& BlockLatticeView3D<T,Lattice>::getDataAnalysis() const {
    dataAnalysis -> reset();
    return *dataAnalysis;
}

template<typename T, template<typename U> class Lattice>
DataSerializer<T> const& BlockLatticeView3D<T,Lattice>::
    getSerializer(IndexOrdering::OrderingT ordering) const
{
    return originalLattice -> getSubSerializer(x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1, ordering);
}

template<typename T, template<typename U> class Lattice>
DataUnSerializer<T>& BlockLatticeView3D<T,Lattice>::
    getUnSerializer(IndexOrdering::OrderingT ordering)
{
    return originalLattice -> getSubUnSerializer(x0, x0+nx-1, y0, y0+ny-1, z0, z0+nz-1, ordering);
}

template<typename T, template<typename U> class Lattice>
DataSerializer<T> const& BlockLatticeView3D<T,Lattice>::getSubSerializer (
            int x0_, int x1_, int y0_, int y1_, int z0_, int z1_,
            IndexOrdering::OrderingT ordering ) const
{
    return originalLattice -> getSubSerializer(x0_+x0, x1_+x0, y0_+y0, y1_+y0, z0_+z0, z1_+z0, ordering);
}

template<typename T, template<typename U> class Lattice>
DataUnSerializer<T>& BlockLatticeView3D<T,Lattice>::getSubUnSerializer (
            int x0_, int x1_, int y0_, int y1_, int z0_, int z1_,
            IndexOrdering::OrderingT ordering )
{
    return originalLattice -> getSubUnSerializer(x0_+x0, x1_+x0, y0_+y0, y1_+y0, z0_+z0, z1_+z0, ordering);
}

template<typename T, template<typename U> class Lattice>
MultiDataDistribution3D BlockLatticeView3D<T,Lattice>::getDataDistribution() const {
    return MultiDataDistribution3D(getNx(), getNy(), getNz());
}

template<typename T, template<typename U> class Lattice>
SpatiallyExtendedObject3D* BlockLatticeView3D<T,Lattice>::getComponent(int iBlock) {
    OLB_PRECONDITION( iBlock==0 );
    return this;
}

template<typename T, template<typename U> class Lattice>
SpatiallyExtendedObject3D const* BlockLatticeView3D<T,Lattice>::getComponent(int iBlock) const {
    OLB_PRECONDITION( iBlock==0 );
    return this;
}

template<typename T, template<typename U> class Lattice>
multiPhysics::MultiPhysicsId BlockLatticeView3D<T,Lattice>::getMultiPhysicsId() const {
    return multiPhysics::getMultiPhysicsBlockId<T,Lattice>();
}


}  // namespace olb

#endif