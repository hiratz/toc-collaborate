/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2008 Andrea Parmigiani, Orestis Malaspinas, 
 *  Jonas Latt
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
 * Descriptor for all types of 2D and 3D lattices. In principle, thanks
 * to the fact that the OpenLB code is generic, it is sufficient to
 * write a new descriptor when a new type of lattice is to be used.
 *  -- generic code
 */
#ifndef FORCED_SHAN_CHEN_LATTICE_DESCRIPTORS_HH
#define FORCED_SHAN_CHEN_LATTICE_DESCRIPTORS_HH

#include "forcedShanChenLatticeDescriptors.h"

namespace olb {

namespace descriptors {

    // Shan-Chen D2Q9 ////////////////////////////////////////////////////////////

    template<typename T>
    const int ForcedShanChenD2Q9Descriptor<T>::c
        [ForcedShanChenD2Q9Descriptor<T>::q][ForcedShanChenD2Q9Descriptor<T>::d] =
        {
            { 0, 0},
            {-1, 1}, {-1, 0}, {-1,-1}, { 0,-1},
            { 1,-1}, { 1, 0}, { 1, 1}, { 0, 1}
        };

    template<typename T>
    const T ForcedShanChenD2Q9Descriptor<T>::t[ForcedShanChenD2Q9Descriptor<T>::q] =
        {
            (T)4/(T)9, (T)1/(T)36, (T)1/(T)9, (T)1/(T)36, (T)1/(T)9,
                       (T)1/(T)36, (T)1/(T)9, (T)1/(T)36, (T)1/(T)9
        };

    template<typename T>
    const T ForcedShanChenD2Q9Descriptor<T>::invCs2 = (T)3;


    // Shan-Chen D3Q19 ///////////////////////////////////////////////////////////

    template<typename T>
    const int ForcedShanChenD3Q19Descriptor<T>::c
        [ForcedShanChenD3Q19Descriptor<T>::q][ForcedShanChenD3Q19Descriptor<T>::d] =
        {
            { 0, 0, 0},

            {-1, 0, 0}, { 0,-1, 0}, { 0, 0,-1},
            {-1,-1, 0}, {-1, 1, 0}, {-1, 0,-1},
            {-1, 0, 1}, { 0,-1,-1}, { 0,-1, 1},

            { 1, 0, 0}, { 0, 1, 0}, { 0, 0, 1},
            { 1, 1, 0}, { 1,-1, 0}, { 1, 0, 1},
            { 1, 0,-1}, { 0, 1, 1}, { 0, 1,-1}
        }; 
 
    template<typename T>
    const T ForcedShanChenD3Q19Descriptor<T>::t[ForcedShanChenD3Q19Descriptor<T>::q] =
        {
            (T)1/(T)3,

            (T)1/(T)18, (T)1/(T)18, (T)1/(T)18, 
            (T)1/(T)36, (T)1/(T)36, (T)1/(T)36,
            (T)1/(T)36, (T)1/(T)36, (T)1/(T)36,

            (T)1/(T)18, (T)1/(T)18, (T)1/(T)18, 
            (T)1/(T)36, (T)1/(T)36, (T)1/(T)36,
            (T)1/(T)36, (T)1/(T)36, (T)1/(T)36
        };

    template<typename T>
    const T ForcedShanChenD3Q19Descriptor<T>::invCs2 = (T)3;



}  // namespace descriptors

}  // namespace olb

#endif
