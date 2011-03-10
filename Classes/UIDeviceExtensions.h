/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@interface UIDevice (UIDeviceOBAExtensions)

// Returns whether multitasking is supported on this device/version of iOS or not.
// Will work even if called on iPhone OS 3.0, unlike the standard isMultitaskingSupported.
- (BOOL)isMultitaskingSupportedSafe;

/**
 * Returns whether MKPolyline is supported.  This was introduced in iOS 4.x
 */
- (BOOL)isMKPolylineSupportedSafe;

/**
 * Returns whether MKMapView.overlays is supported.  This was introduced in iOS 4.x
 */
- (BOOL)isMKMapViewOverlaysSupportedSafe:(MKMapView*)mapView;

/**
 * Returns whether NSRegularExpression is supported.  This was introduced in iOS 4.x
 */
- (BOOL)isNSRegularExpressionSupported;

@end
