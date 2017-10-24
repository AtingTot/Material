/*
 * Copyright (C) 2015 - 2017, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.com>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

open class TabItem: FlatButton {
    open override func prepare() {
        super.prepare()
        pulseAnimation = .none
    }
    
    open override var isHighlighted: Bool {
        didSet {
            tintColor = titleColor(for: isHighlighted ? .highlighted : isSelected ? .selected : .normal)
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            tintColor = titleColor(for: isSelected ? .selected : .normal)
        }
    }
}

@objc(TabItemState)
public enum TabItemState: Int {
    case normal
    case highlighted
    case selected
}

@objc(TabItemLineState)
public enum TabItemLineState: Int {
    case selected
}

@objc(TabBarLineAlignment)
public enum TabBarLineAlignment: Int {
    case top
    case bottom
}

@objc(TabBarDelegate)
public protocol TabBarDelegate {
    /**
     A delegation method that is executed to determine if the TabBar should
     transition to the next tab.
     - Parameter tabBar: A TabBar.
     - Parameter tabItem: A TabItem.
     - Returns: A Boolean.
     */
    @objc
    optional func tabBar(tabBar: TabBar, shouldSelect tabItem: TabItem) -> Bool
    
    /**
     A delegation method that is executed when the tabItem will trigger the
     animation to the next tab.
     - Parameter tabBar: A TabBar.
     - Parameter tabItem: A TabItem.
     */
    @objc
    optional func tabBar(tabBar: TabBar, willSelect tabItem: TabItem)
    
    /**
     A delegation method that is executed when the tabItem did complete the
     animation to the next tab.
     - Parameter tabBar: A TabBar.
     - Parameter tabItem: A TabItem.
     */
    @objc
    optional func tabBar(tabBar: TabBar, didSelect tabItem: TabItem)
}

@objc(_TabBarDelegate)
internal protocol _TabBarDelegate {
    /**
     A delegation method that is executed when the tabItem will trigger the
     animation to the next tab.
     - Parameter tabBar: A TabBar.
     - Parameter tabItem: A TabItem.
     */
    @objc
    optional func _tabBar(tabBar: TabBar, willSelect tabItem: TabItem)
}

@objc(TabBarStyle)
public enum TabBarStyle: Int {
    case auto
    case nonScrollable
    case scrollable
}

open class TabBar: Bar {
    /// Only for inital load to get the line animation correct.
    fileprivate var shouldNotAnimateLineView = false
    
    /// The total width of the tabItems.
    fileprivate var tabItemsTotalWidth: CGFloat {
        var w: CGFloat = 0
        let q = 2 * tabItemsInterimSpace
        let p = q + tabItemsInterimSpace
        
        for v in tabItems {
            let x = v.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: scrollView.bounds.height)).width
            w += x
            w += p
        }
        
        w -= tabItemsInterimSpace
        
        return w
    }
    
    /// A dictionary of TabItemStates to UIColors for tabItems.
    fileprivate var tabItemsColorForState = [TabItemState: UIColor]()
    
    /// A dictionary of TabItemLineStates to UIColors for the line.
    fileprivate var lineColorForState = [TabItemLineState: UIColor]()
    
    /// An enum that determines the tab bar style.
    open var tabBarStyle = TabBarStyle.auto {
        didSet {
            layoutSubviews()
        }
    }
    
    /// A reference to the scroll view when the tab bar style is scrollable.
    open let scrollView = UIScrollView()
    
    /// Enables and disables bouncing when swiping.
    open var isScrollBounceEnabled: Bool {
        get {
            return scrollView.bounces
        }
        set(value) {
            scrollView.bounces = value
        }
    }
    
    /// A delegation reference.
    open weak var delegate: TabBarDelegate?
    internal weak var _delegate: _TabBarDelegate?
    
    /// The currently selected tabItem.
    open internal(set) var selectedTabItem: TabItem? {
        willSet {
            selectedTabItem?.isSelected = false
        }
        
        didSet {
            selectedTabItem?.isSelected = true
        }
    }
    
    /// A preset wrapper around tabItems contentEdgeInsets.
    open var tabItemsContentEdgeInsetsPreset: EdgeInsetsPreset {
        get {
            return contentView.grid.contentEdgeInsetsPreset
        }
        set(value) {
            contentView.grid.contentEdgeInsetsPreset = value
        }
    }
    
    /// A reference to EdgeInsets.
    @IBInspectable
    open var tabItemsContentEdgeInsets: EdgeInsets {
        get {
            return contentView.grid.contentEdgeInsets
        }
        set(value) {
            contentView.grid.contentEdgeInsets = value
        }
    }
    
    /// A preset wrapper around tabItems interimSpace.
    open var tabItemsInterimSpacePreset: InterimSpacePreset {
        get {
            return contentView.grid.interimSpacePreset
        }
        set(value) {
            contentView.grid.interimSpacePreset = value
        }
    }
    
    /// A wrapper around tabItems interimSpace.
    @IBInspectable
    open var tabItemsInterimSpace: InterimSpace {
        get {
            return contentView.grid.interimSpace
        }
        set(value) {
            contentView.grid.interimSpace = value
        }
    }
    
    /// TabItems.
    @objc
    open var tabItems = [TabItem]() {
        didSet {
            for b in oldValue {
                b.removeFromSuperview()
            }
            
            prepareTabItems()
            
            layoutSubviews()
        }
    }

    /// A reference to the line UIView.
    open let line = UIView()
    
    /// A value for the line alignment.
    @objc
    open var lineAlignment = TabBarLineAlignment.bottom {
        didSet {
            layoutSubviews()
        }
    }
    
    /// The line height.
    @objc
    open var lineHeight: CGFloat {
        get {
            return line.bounds.height
        }
        set(value) {
            line.frame.size.height = value
        }
    }
    
    /// The line color.
    @objc
    open var lineColor: UIColor {
        get {
            return lineColorForState[.selected]!
        }
        set(value) {
            lineColorForState[.selected] = value
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard willLayout else {
            return
        }
        
        layoutScrollView()
        layoutLine()
        
        updateScrollView()
    }
    
    open override func prepare() {
        super.prepare()
        contentEdgeInsetsPreset = .none
        interimSpacePreset = .interimSpace6
        tabItemsInterimSpacePreset = .interimSpace4
        
        prepareContentView()
        prepareScrollView()
        prepareDivider()
        prepareLine()
        prepareTabItemsColor()
        prepareLineColor()
        
        updateTabItemColors()
        updateLineColors()
    }
}

fileprivate extension TabBar {
    // Prepares the line.
    func prepareLine() {
        line.layer.zPosition = 10000
        lineHeight = 3
        scrollView.addSubview(line)
    }
    
    /// Prepares the divider.
    func prepareDivider() {
        dividerColor = Color.grey.lighten2
        dividerAlignment = .top
    }
    
    /// Prepares the tabItems.
    func prepareTabItems() {
        shouldNotAnimateLineView = true
        
        for v in tabItems {
            v.grid.columns = 0
            v.contentEdgeInsets = .zero
            
            prepareTabItemHandler(tabItem: v)
        }
        
        selectedTabItem = tabItems.first
    }
    
    /// Prepares the tabsItems colors.
    func prepareTabItemsColor() {
        tabItemsColorForState[.normal] = Color.grey.base
        tabItemsColorForState[.selected] = Color.blue.base
        tabItemsColorForState[.highlighted] = Color.blue.base
    }
    
    /// Prepares the line colors.
    func prepareLineColor() {
        lineColorForState[.selected] = Color.blue.base
    }
    
    /**
     Prepares the tabItem animation handler.
     - Parameter tabItem: A TabItem.
     */
    func prepareTabItemHandler(tabItem: TabItem) {
        removeTabItemHandler(tabItem: tabItem)
        
        tabItem.addTarget(self, action: #selector(handleTabItemsChange(tabItem:)), for: .touchUpInside)
    }
    
    /// Prepares the contentView.
    func prepareContentView() {
        contentView.layer.zPosition = 6000
    }
    
    /// Prepares the scroll view. 
    func prepareScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        centerViews = [scrollView]
    }
}

fileprivate extension TabBar {
    /// Layout the scrollView.
    func layoutScrollView() {
        contentView.grid.reload()
        
        if .scrollable == tabBarStyle || (.auto == tabBarStyle && tabItemsTotalWidth > scrollView.bounds.width) {
            var w: CGFloat = 0
            let q = 2 * tabItemsInterimSpace
            let p = q + tabItemsInterimSpace
            
            for v in tabItems {
                let x = v.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: scrollView.bounds.height)).width
                v.frame.size.height = scrollView.bounds.height
                v.frame.size.width = x + q
                v.frame.origin.x = w
                w += x
                w += p
                
                if scrollView != v.superview {
                    v.removeFromSuperview()
                    scrollView.addSubview(v)
                }
            }
            
            w -= tabItemsInterimSpace
            
            scrollView.contentSize = CGSize(width: w, height: scrollView.bounds.height)
            
        } else {
            scrollView.grid.begin()
            scrollView.grid.views = tabItems
            scrollView.grid.axis.columns = tabItems.count
            scrollView.grid.contentEdgeInsets = tabItemsContentEdgeInsets
            scrollView.grid.interimSpace = tabItemsInterimSpace
            scrollView.grid.commit()
            scrollView.contentSize = scrollView.frame.size
        }
    }
    
    /// Layout the line view.
    func layoutLine() {
        guard let v = selectedTabItem else {
            return
        }
        
        guard shouldNotAnimateLineView else {
            line.animate(.duration(0),
                         .size(width: v.bounds.width, height: lineHeight),
                         .position(x: v.center.x, y: .bottom == lineAlignment ? bounds.height - lineHeight / 2 : lineHeight / 2))
            return
        }
        
        line.frame = CGRect(x: v.frame.origin.x, y: .bottom == lineAlignment ? scrollView.bounds.height - lineHeight : 0, width: v.bounds.width, height: lineHeight)
        
        shouldNotAnimateLineView = false
    }
}

fileprivate extension TabBar {
    /**
     Removes the tabItem animation handler.
     - Parameter tabItem: A TabItem.
     */
    func removeTabItemHandler(tabItem: TabItem) {
        tabItem.removeTarget(self, action: #selector(handleTabItemsChange(tabItem:)), for: .touchUpInside)
    }
}

fileprivate extension TabBar {
    /// Handles the tabItem touch event.
    @objc
    func handleTabItemsChange(tabItem: TabItem) {
        guard !(false == delegate?.tabBar?(tabBar: self, shouldSelect: tabItem)) else {
            return
        }
        
        animate(to: tabItem, isTriggeredByUserInteraction: true)
    }
}

extension TabBar {
    /**
     Selects a given index from the tabItems array.
     - Parameter at index: An Int.
     - Paramater completion: An optional completion block.
     */
    @objc
    open func select(at index: Int, completion: ((TabItem) -> Void)? = nil) {
        guard -1 < index, index < tabItems.count else {
            return
        }
        
        animate(to: tabItems[index], isTriggeredByUserInteraction: false, completion: completion)
    }
    
    /**
     Animates to a given tabItem.
     - Parameter to tabItem: A TabItem.
     - Parameter completion: An optional completion block.
     */
    open func animate(to tabItem: TabItem, completion: ((TabItem) -> Void)? = nil) {
        animate(to: tabItem, isTriggeredByUserInteraction: false, completion: completion)
    }
}

extension TabBar {
    /**
     Retrieves the tabItem color for a given state.
     - Parameter for state: A TabItemState.
     - Returns: A UIColor.
     */
    open func getTabItemColor(for state: TabItemState) -> UIColor {
        return tabItemsColorForState[state]!
    }
    
    /**
     Sets the color for the tabItems given a TabItemState.
     - Parameter _ color: A UIColor.
     - Parameter for state: A TabItemState.
     */
    open func setTabItemsColor(_ color: UIColor, for state: TabItemState) {
        tabItemsColorForState[state] = color
        updateTabItemColors()
    }
    
    /**
     Retrieves the line color for a given state.
     - Parameter for state: A TabItemLineState.
     - Returns: A UIColor.
     */
    open func getLineColor(for state: TabItemLineState) -> UIColor {
        return lineColorForState[state]!
    }
    
    /**
     Sets the color for the line given a TabItemLineState.
     - Parameter _ color: A UIColor.
     - Parameter for state: A TabItemLineState.
     */
    open func setLineColor(_ color: UIColor, for state: TabItemLineState) {
        lineColorForState[state] = color
        updateLineColors()
    }
}

fileprivate extension TabBar {
    /// Updates the tabItems colors.
    func updateTabItemColors() {
        let normalColor = tabItemsColorForState[.normal]
        let selectedColor = tabItemsColorForState[.selected]
        let highlightedColor = tabItemsColorForState[.highlighted]
        
        for v in tabItems {
            v.setTitleColor(normalColor, for: .normal)
            v.setTitleColor(selectedColor, for: .selected)
            v.setTitleColor(highlightedColor, for: .highlighted)
            v.tintColor = normalColor
        }
        
        selectedTabItem?.tintColor = selectedColor
    }
    
    /// Updates the line colors.
    func updateLineColors() {
        line.backgroundColor = lineColorForState[.selected]
    }
}

fileprivate extension TabBar {
    /**
     Animates to a given tabItem.
     - Parameter to tabItem: A TabItem.
     - Parameter isTriggeredByUserInteraction: A boolean indicating whether the
     state was changed by a user interaction, true if yes, false otherwise.
     - Parameter completion: An optional completion block.
     */
    func animate(to tabItem: TabItem, isTriggeredByUserInteraction: Bool, completion: ((TabItem) -> Void)? = nil) {
        if isTriggeredByUserInteraction {
            _delegate?._tabBar?(tabBar: self, willSelect: tabItem)
            delegate?.tabBar?(tabBar: self, willSelect: tabItem)
        }
        
        selectedTabItem = tabItem
        
        line.animate(.duration(0.25),
                     .size(width: tabItem.bounds.width, height: lineHeight),
                     .position(x: tabItem.center.x, y: .bottom == lineAlignment ? bounds.height - lineHeight / 2 : lineHeight / 2),
                     .completion({ [weak self, isTriggeredByUserInteraction = isTriggeredByUserInteraction, tabItem = tabItem, completion = completion] in
                        guard let s = self else {
                            return
                        }
                        
                        if isTriggeredByUserInteraction {
                            s.delegate?.tabBar?(tabBar: s, didSelect: tabItem)
                        }
                        
                        completion?(tabItem)
                     }))
        
        updateScrollView()
    }
}

fileprivate extension TabBar {
    /// Updates the scrollView.
    func updateScrollView() {
        guard let v = selectedTabItem else {
            return
        }
        
        if !scrollView.bounds.contains(v.frame) {
            let contentOffsetX = (v.frame.origin.x < scrollView.bounds.minX) ? v.frame.origin.x : v.frame.maxX - scrollView.bounds.width
            let normalizedOffsetX = min(max(contentOffsetX, 0), scrollView.contentSize.width - scrollView.bounds.width)
            scrollView.setContentOffset(CGPoint(x: normalizedOffsetX, y: 0), animated: true)
        }
    }
}
