/*  This file is part of the OpenLB library
 *
 *  Copyright (C) 2007 Orestis Malaspinas, Jonas Latt
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

#include "inamuroAnalyticalDynamics.h"
#include "inamuroAnalyticalDynamics.hh"
#include "core/latticeDescriptors.h"
#include "core/latticeDescriptors.hh"


namespace olb {

class InamuroAnalyticalDynamics <
    double, descriptors::D2Q9Descriptor, BGKdynamics<double,descriptors::D2Q9Descriptor>, 0, 1 >;
class InamuroAnalyticalDynamics <
    double, descriptors::D2Q9Descriptor, BGKdynamics<double,descriptors::D2Q9Descriptor>, 0, -1 >;
class InamuroAnalyticalDynamics <
    double, descriptors::D2Q9Descriptor, BGKdynamics<double,descriptors::D2Q9Descriptor>, 1, 1 >;
class InamuroAnalyticalDynamics <
    double, descriptors::D2Q9Descriptor, BGKdynamics<double,descriptors::D2Q9Descriptor>, 1, -1 >;

}  // namespace olb