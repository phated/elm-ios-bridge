import UIKit
import YogaKit
import JavaScriptCore


class VirtualUIKit : NSObject {
    
    static var rootView : UIView? = nil
    
    /* APPLY PATCHES */
    
    static func applyPatches(_ patches: [String : Any]) {
        // TODO consider handling patches to root node seperately
        if let view = rootView {
            let patchList = addUIKitNodes(rootView: view, patches: patches)
            for patch in patchList {
                applyPatch(patch)
            }
        }
    }
    
    static func applyPatch(_ patch: [String : Any]) {
        if let type = patch["type"] as? String, let node = patch["node"] as? UIView {
            switch type {
            case "redraw":
                if let virtualNode = patch["data"] as? [String : Any ], let newNode = render(virtualView: virtualNode) {
                    if let parent = node.superview {
                        replaceSubview(parent: parent, old: node, new: newNode)
                        parent.yoga.applyLayout(preservingOrigin: true)
                    }
                }
            default:
                return
            }
        }
    }
    
    static func replaceSubview(parent: UIView, old: UIView, new: UIView) {
        parent.insertSubview(new, belowSubview: old)
        old.removeFromSuperview()
    }
    
    /* ADD UIKIT NODES TO PATCHES */

    
    static func addUIKitNodesRecursive(view: UIView, patch: inout [String : Any]) {
        if let cons = patch["cons"] as? String, cons != "change", let index = patch["index"] as? Int, let patches = patch["patches"] as? [[String : Any]] {
            let subview = view.subviews[index]
            for var p in patches {
                addUIKitNodesRecursive(view: subview, patch: &p)
            }
        } else {
            patch["node"] = view
        }
    }
    
    static func addUIKitNodes(rootView: UIView, patches: [String : Any]) -> [[String : Any]] {
        var queue : [([String : Any], UIView)] = [(patches, rootView)]
        var patchList : [[String : Any]] = []
        while !queue.isEmpty {
            var (patch, view) = queue.removeLast()
            if let cons = patch["cons"] as? String, cons == "at", let index = patch["index"] as? Int, let patches = patch["patches"] as? [[String : Any]] {
                let subview = view.subviews[index]
                queue.append(contentsOf: patches.map { ($0, subview) })
            } else {
                patch["node"] = view
                patchList.append(patch)
            }
        }
        return patchList
    }

    /* RENDER */

    static func render(virtualView: [String : Any]) -> UIView? {
        if let tag = virtualView["tag"] as? String, let facts = virtualView["facts"] as? [String : Any] {
            switch tag {
            case "label":
                return renderLabel(facts: facts)
            case "view":
                if let children = virtualView["children"] as? [[String : Any]] {
                    return renderView(facts: facts, children: children)
                }
            default:
                return nil
            }
        }
        return nil
    }

    static func renderLabel(facts: [String : Any]) -> UILabel {
        let label: UILabel = UILabel()

        if let text = facts["text"] as? String {
            label.text = text
        }

        // textColor
        if let textColor = facts["textColor"] as? String, let color = extractColor(textColor) {
            label.textColor = color
        }

        // textAlignment
        if let textAlignment = facts["textAlignment"] as? String {
            // TODO store textAlignment as an Int in JSON and use rawValue
            label.textAlignment = extractTextAlignment(textAlignment)
        }

        // font
        if let font = facts["font"] as? String {
            label.font = UIFont(name: font, size: facts["fontSize"] as? CGFloat ?? UIFont.systemFontSize)
        } else if let fontSize = facts["fontSize"] as? CGFloat {
            label.font = UIFont.systemFont(ofSize: fontSize)
        }

        // numberOfLines
        if let numberOfLines = facts["numberOfLines"] as? Int {
            label.numberOfLines = numberOfLines
        }

        // lineBreakMode
        if let lineBreakMode = facts["lineBreakMode"] as? String {
            // TODO store lineBreakMode as an Int in JSON and use rawValue
            label.lineBreakMode = extractLineBreakMode(lineBreakMode)
        }

        // isEnabled
        if let isEnabled = facts["isEnabled"] as? Bool {
            label.isEnabled = isEnabled
        }

        // highlight
        if let isHighlighted = facts["isHighlighted"] as? Bool {
            label.isHighlighted = isHighlighted
        }

        if let highlightedTextColor = facts["highlightedTextColor"] as? String, let color = extractColor(highlightedTextColor) {
            label.highlightedTextColor = color
        }

        // shadow
        if let shadowColor = facts["shadowColor"] as? String, let color = extractColor(shadowColor) {
            label.shadowColor = color
            if let shadowOffsetX = facts["shadowOffsetX"] as? CGFloat, let shadowOffsetY = facts["shadowOffsetY"] as? CGFloat {
                label.shadowOffset = CGSize(width: shadowOffsetX, height: shadowOffsetY)
            }
        }

        applyYogaFacts(view: label, facts: facts)

        return label
    }

    static func renderView(facts: [String : Any], children: [[String : Any]]) -> UIView {
        let view: UIView = UIView()

        if let backgroundColor = facts["backgroundColor"] as? String {
            view.backgroundColor = extractColor(backgroundColor)
        }

        applyYogaFacts(view: view, facts: facts)

        for child in children {
            if let renderedChild = render(virtualView: child) {
                view.addSubview(renderedChild)
            }
        }

        return view
    }

    static func extractTextAlignment(_ alignment: String) -> NSTextAlignment {
        switch alignment {
        case "left":
            return .left
        case "right":
            return .right
        case "center":
            return .center
        case "justified":
            return .justified
        case "natural":
            return .natural
        default:
            return .left
        }
    }

    static func extractColor(_ color: String) -> UIColor? {
        switch color {
            case "red":
                return .red
            case "orange":
                return .orange
            case "yellow":
                return .yellow
            case "green":
                return .green
            case "cyan":
                return .cyan
            case "blue":
                return .blue
            case "magenta":
                return .magenta
            case "purple":
                return .purple
            case "white":
                return .white
            case "gray":
                return .gray
            case "black":
                return .black
            case "brown":
                return .brown
            default:
                return nil
        }
    }

    static func extractLineBreakMode(_ lbM: String) -> NSLineBreakMode {
        switch lbM {
        case "":
            return .byWordWrapping
        case "":
            return .byCharWrapping
        case "":
            return .byClipping
        case "":
            return .byTruncatingHead
        case "":
            return .byTruncatingTail
        case "":
            return .byTruncatingMiddle
        default:
            return .byTruncatingTail
        }
    }

    static func extractFlexDirection(_ direction: String) -> YGFlexDirection {
        switch direction {
        case "row":
            return .row
        case "colum":
            return .column
        case "rowReverse":
            return .rowReverse
        case "columnReverse":
            return .columnReverse
        default:
            return .column
        }
    }

    static func extractJustify(_ justify: String) -> YGJustify {
        switch justify {
        case "flexStart":
            return .flexStart
        case "flexEnd":
            return .flexEnd
        case "center":
            return .center
        case "spaceBetween":
            return .spaceBetween
        case "spaceAround":
            return .spaceAround
        default:
            return .flexStart
        }
    }

    static func extractWrap(_ wrap: String) -> YGWrap {
        switch wrap {
        case "noWrap":
            return .noWrap
        case "wrap":
            return .wrap
        case "wrapReverse":
            return .wrapReverse
        default:
            return .noWrap
        }
    }

    static func extractAlign(_ align: String) -> YGAlign? {
        switch align {
        case "stretch":
            return .stretch
        case "flexStart":
            return .flexStart
        case "flexEnd":
            return .flexEnd
        case "center":
            return .center
        default:
            return nil
        }
    }

    static func extractTextDirection(_ direction: String) -> YGDirection {
        switch direction {
        case "inherit":
            return .inherit
        case "LTR":
            return .LTR
        case "RTL":
            return .RTL
        default:
            return .inherit
        }
    }

    static func applyYogaFacts(view: UIView, facts: [String : Any]) {
        view.configureLayout { (layout) in
            layout.isEnabled = true

            for key in facts.keys {
                switch key {
                case "yogaEnabled":
                    if let value = facts[key] as? Bool {
                        layout.isEnabled = value
                    }
                    break

                // Container properties

                case "flexDirection":
                    if let value = facts[key] as? String {
                        // TODO store flexDirection as an Int in JSON and use rawValue
                        layout.flexDirection = extractFlexDirection(value)
                    }
                    break

                case "justifyContent":
                    if let value = facts[key] as? String {
                        // TODO store justifyContent as an Int in JSON and use rawValue
                        layout.justifyContent = extractJustify(value)
                    }
                    break

                case "flexWrap":
                    if let value = facts[key] as? String {
                        // TODO store flexWrap as an Int in JSON and use rawValue
                        layout.flexWrap = extractWrap(value)
                    }
                    break

                case "alignItems":
                    if let value = facts[key] as? String {
                        // TODO store alignItems as an Int in JSON and use rawValue
                        layout.alignItems = extractAlign(value) ?? .stretch
                    }
                    break

                case "alignContent":
                    if let value = facts[key] as? String {
                        // TODO store alignContent as an Int in JSON and use rawValue
                        layout.alignContent = extractAlign(value) ?? .flexStart
                    }
                    break

                case "direction":
                    if let value = facts[key] as? String {
                        layout.direction = extractTextDirection(value)
                    }


                // Other properties

                case "alignSelf":
                    if let value = facts[key] as? String, let align = extractAlign(value) {
                        // TODO store alignSelf as an Int in JSON and use rawValue
                        layout.alignItems = align
                    }
                    break

                case "position":
                    if let value = facts[key] as? String, value == "absolute" {
                        layout.position = .absolute
                    }
                    break


                // YGValue

                case "flexBasis":
                    if let value = facts[key] as? Float {
                        layout.flexBasis = YGValue(value)
                    }
                    break

                case "left":
                    if let value = facts[key] as? Float {
                        layout.left = YGValue(value)
                    }
                    break
                case "top":
                    if let value = facts[key] as? Float {
                        layout.top = YGValue(value)
                    }
                    break
                case "right":
                    if let value = facts[key] as? Float {
                        layout.right = YGValue(value)
                    }
                    break
                case "bottom":
                    if let value = facts[key] as? Float {
                        layout.bottom = YGValue(value)
                    }
                    break
                case "start":
                    if let value = facts[key] as? Float {
                        layout.start = YGValue(value)
                    }
                    break
                case "end":
                    if let value = facts[key] as? Float {
                        layout.end = YGValue(value)
                    }
                    break

                case "minWidth":
                    if let value = facts[key] as? Float {
                        layout.minWidth = YGValue(value)
                    }
                    break
                case "minHeight":
                    if let value = facts[key] as? Float {
                        layout.minHeight = YGValue(value)
                    }
                    break
                case "maxWidth":
                    if let value = facts[key] as? Float {
                        layout.maxWidth = YGValue(value)
                    }
                    break
                case "maxHeight":
                    if let value = facts[key] as? Float {
                        layout.maxHeight = YGValue(value)
                    }
                    break

                case "width":
                    if let value = facts[key] as? Float {
                        layout.width = YGValue(value)
                    }
                    break
                case "height":
                    if let value = facts[key] as? Float {
                        layout.height = YGValue(value)
                    }
                    break

                case "margin":
                    if let value = facts[key] as? Float {
                        layout.margin = YGValue(value)
                    }
                    break
                case "marginLeft":
                    if let value = facts[key] as? Float {
                        layout.marginLeft = YGValue(value)
                    }
                    break
                case "marginTop":
                    if let value = facts[key] as? Float {
                        layout.marginTop = YGValue(value)
                    }
                    break
                case "marginRight":
                    if let value = facts[key] as? Float {
                        layout.marginRight = YGValue(value)
                    }
                    break
                case "marginBottom":
                    if let value = facts[key] as? Float {
                        layout.marginBottom = YGValue(value)
                    }
                    break
                case "marginStart":
                    if let value = facts[key] as? Float {
                        layout.marginStart = YGValue(value)
                    }
                    break
                case "marginEnd":
                    if let value = facts[key] as? Float {
                        layout.marginEnd = YGValue(value)
                    }
                    break
                case "marginVertical":
                    if let value = facts[key] as? Float {
                        layout.marginVertical = YGValue(value)
                    }
                    break
                case "marginHorizontal":
                    if let value = facts[key] as? Float {
                        layout.marginHorizontal = YGValue(value)
                    }
                    break

                case "padding":
                    if let value = facts[key] as? Float {
                        layout.padding = YGValue(value)
                    }
                    break
                case "paddingLeft":
                    if let value = facts[key] as? Float {
                        layout.paddingLeft = YGValue(value)
                    }
                    break
                case "paddingTop":
                    if let value = facts[key] as? Float {
                        layout.paddingTop = YGValue(value)
                    }
                    break
                case "paddingRight":
                    if let value = facts[key] as? Float {
                        layout.paddingRight = YGValue(value)
                    }
                    break
                case "paddingBottom":
                    if let value = facts[key] as? Float {
                        layout.paddingBottom = YGValue(value)
                    }
                    break
                case "paddingStart":
                    if let value = facts[key] as? Float {
                        layout.paddingStart = YGValue(value)
                    }
                    break
                case "paddingEnd":
                    if let value = facts[key] as? Float {
                        layout.paddingEnd = YGValue(value)
                    }
                    break
                case "paddingVertical":
                    if let value = facts[key] as? Float {
                        layout.paddingVertical = YGValue(value)
                    }
                    break
                case "paddingHorizontal":
                    if let value = facts[key] as? Float {
                        layout.paddingHorizontal = YGValue(value)
                    }
                    break


                // CGFloat

                case "flexGrow":
                    if let value = facts[key] as? Float {
//                        layout.setValue(CGFloat(value), forKey: key)
                        layout.flexGrow = CGFloat(value)
                    }
                case "flexShrink":
                    if let value = facts[key] as? Float {
                        layout.flexShrink = CGFloat(value)
                    }

                case "borderWidth":
                    if let value = facts[key] as? Float {
                        layout.borderWidth = CGFloat(value)
                    }
                case "borderLeftWidth":
                    if let value = facts[key] as? Float {
                        layout.borderLeftWidth = CGFloat(value)
                    }
                case "borderTopWidth":
                    if let value = facts[key] as? Float {
                        layout.borderTopWidth = CGFloat(value)
                    }
                case "borderRightWidth":
                    if let value = facts[key] as? Float {
                        layout.borderRightWidth = CGFloat(value)
                    }
                case "borderBottomWidth":
                    if let value = facts[key] as? Float {
                        layout.borderBottomWidth = CGFloat(value)
                    }
                case "borderStartWidth":
                    if let value = facts[key] as? Float {
                        layout.borderStartWidth = CGFloat(value)
                    }
                case "borderEndWidth":
                    if let value = facts[key] as? Float {
                        layout.borderEndWidth = CGFloat(value)
                    }

                case "aspectRatio":
                    if let value = facts[key] as? Float {
                        layout.aspectRatio = CGFloat(value)
                    }
                    break

                default:
                    break
                }
            }
        }
    }
}

