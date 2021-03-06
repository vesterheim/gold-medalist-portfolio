# Title: Jekyll auto_nav generator for Vesterheim
# Authors: Faust Gertz :faust@faustgertz.com
#
# Description: Generates useful navigation stuff in site.data.
#              Inspired by Concrete5's auto_nav
# 
# Generates the following:
# 
# site.data.auto_nav_hash = { page.url => {
# 		'title' =>  
# 		'short_title' =>
# 		'page_title' => 
# 		'breadcrumb' => {
# 			'title' =>  
# 			'short_title' =>
# 		},
# 		'url' => Page URL
# 		'order' => page.navigation.order || 1000,
# 		'ancestors' => array of ancestor URLs
# 		'root' => URL of root
# 		'parent' => URL of parent
# 		'level' => depth in site
# 		'handle' => slugify version of name
# 		'id' => slugify version of URL
# 	},
#   etc....	
# }
#
# site.data.auto_nav = [
# 	{
# 		'title' =>  
# 		'short_title' =>
# 		'page_title' => 
# 		'breadcrumb' => {
# 			'title' =>  
# 			'short_title' =>
# 		},
# 		'url' => Page URL
# 		'order' => page.navigation.order || 1000,
# 		'ancestors' => array of ancestor URLs
# 		'root' => URL of root
# 		'parent' => URL of parent
# 		'level' => depth in site
# 		'handle' => slugify version of name
# 		'id' => slugify version of URL
#       'has_children?' => Boolean if there are children
# 		'sub_depth' => current level - level of next node in array
# 	},
#   etc....	
# ]
#
# site.data.auto_nav_site = site.data.auto_nav.select do |n| 
# 	n['level'] == 1
# end
# That is to say, site.data.auto_nav with just the top level
# navigation nodes.
#
# site.data.auto_nav_section_hash = {
#	page.url => site.data.auto_nav.select do |n| 
# 		# filtered to be used for section navigation
# 	end
# }

require './_plugins/vester_utils.rb'

module Jekyll

	class AutoNavGenerator < Generator
		priority :low
		safe true

		def generate(site)

			# All pages and posts
			nodes = site.pages + site.posts

			# All navigable pages and posts for hash
			# Even if navigation['exclude'] == true, we need them 
			# for breadcrumbs and the like.
			navigable_nodes = nodes.select { |node| VesterUtils.is_navigable?(node) }

			# Save results for reuse and add to site.data
			auto_nav_hash = create_auto_nav_hash(navigable_nodes)
			site.data['auto_nav_hash'] = auto_nav_hash
#STDERR.puts auto_nav_hash.inspect
			# Navigable nodes excluding navigation['exclude'] == true
			# that should not appear in menu
			menu_nodes = nodes.select do |node| 
				navigation = node['navigation'] || {}
				VesterUtils.is_navigable?(node) && ! navigation['exclude'] == true
			end
#STDERR.puts menu_nodes.inspect
			# Use info from auto_nav_hash. Save results for reuse. 
			# Add to site.data 
			auto_nav_array = 
				VesterUtils.create_nodes_array(menu_nodes, auto_nav_hash)
			site.data['auto_nav'] = auto_nav_array
#STDERR.puts auto_nav_array.inspect
			# Create hash of auto_nav arrays for each page indexed by URL
			# for section navigation. Add to site.data 
			site.data['auto_nav_section_hash'] = 
				create_auto_nav_section_hash(
					navigable_nodes, 
					auto_nav_array, 
					auto_nav_hash
				)
#STDERR.puts site.data['auto_nav_section_hash'].inspect
#STDERR.puts "site.data['auto_nav_section_hash']".inspect
			# Create top level auto_nav array so we don't do this 
			# {% assign nodes = site.data.auto_nav | where: 'level', 1 %} 
			# twice on every page. Add to site.data 
			site.data['auto_nav_site'] = 
				create_auto_nav_site_array(auto_nav_array)			
		end

		# Create auto_nav hash of navigable pages
		def create_auto_nav_hash(pages)
			hash = {}
			pages.each do |page|
				next unless VesterUtils.is_navigable?(page)
				redirect_to = page['redirect_to'] || Array.new
				navigation = page['navigation'] || {}
				node = {
					'title' => VesterUtils.get_nav_title(page),
					'short_title' => get_nav_short_title(page),
					'page_title' => page['title'] || VesterUtils.get_nav_title(page),
					'breadcrumb' => get_breadcrumb_hash(page),
					'url' => redirect_to.first || page['url'],
					'order' => navigation['order'] || 1000
				}
				node.merge!VesterUtils.create_geneology_hash(page, pages)
				node['level'] = node['ancestors'].size
				node['site_root'] = navigation['site_root'] if navigation['site_root']
				node['handle'] = VesterUtils.generate_handle(node)
				node['id'] = VesterUtils.generate_id(node)
				hash[page['url']] = node
			end				
			hash
		end

		def create_auto_nav_section_hash(navigable_nodes, auto_nav_array, auto_nav_hash)
			# page.url vs page['url'] 
			# they return different values when dealing with Ben's auto generated pages
			# why would page['url'] be necessarly to use with Ben's page generator?
			# Figure out a way to ask about this in Jekyll Issues
			hash = {}
			filter = {}
			navigable_nodes.each do |page|
				filter.clear
				node = auto_nav_hash[page['url']]
				auto_nav_array.
					# Only get nodes for this section
					select { |n| n['root'] == node['root'] }.
					# Build up hash of nodes to include
					each do |menu_item|
						# Get all level one and two nodes
						if menu_item['level'] <= 2
							filter[menu_item['url']] = true
						# Get any ancestor nodes of current page	
						elsif node['ancestors'].include?(menu_item['url'])
							filter[menu_item['url']] = true
						# Get the current page node
						elsif menu_item['url'] == node['url']
							filter[menu_item['url']] = true							
						# Get current page children immediate children nodes
						elsif menu_item['parent'] == node['url']
							filter[menu_item['url']] = true	
						# Get select realtive nodes such as siblings, etc,,
						elsif menu_item['level'] <= node['level']
							node_ancestors = node['ancestors'].
								reverse.
								drop(2)
							menu_item_ancestors = menu_item['ancestors'].
								reverse.
								drop(2).
								each.with_index do |ancestor, i|
									if ancestor == node_ancestors.at(i)
										filter[menu_item['url']] = true
										break
									end
								end
						end
					end
				hash[page['url']] = auto_nav_array.
					select { |n| filter[n['url']] }.
					map { |n| n.clone }
				hash[page['url']] = fix_has_children(hash[page['url']])
				hash[page['url']] = VesterUtils.add_sub_depth(hash[page['url']])
			end
			hash
		end

		def create_auto_nav_site_array(auto_nav_array)
			auto_nav_array.
				select { |n| 
					n['level'] == 1 &&
					n['site_root'] == true
				}.
				map { |n| n.clone }.
				each do |n| 
					n['sub_depth'] = 0
					n['has_children?'] = false
				end
		end

		def get_breadcrumb_hash(page)
			{
				'title' => get_breadcrumb_title(page),
				'short_title' => get_breadcrumb_short_title(page)
			}
		end		

		def get_breadcrumb_short_title(page)
			breadcrumb = page['breadcrumb'] || {}
			breadcrumb['short_title'] || get_nav_short_title(page)
		end	
		
		def get_breadcrumb_title(page)
			breadcrumb = page['breadcrumb'] || {}
			breadcrumb['title'] || VesterUtils.get_nav_title(page)
		end	

		def get_nav_short_title(page)
			navigation = page['navigation'] || {}
			navigation['short_title'] || 
				page['short_title'] || 
				VesterUtils.get_nav_title(page)
		end	

		def fix_has_children(nodes)
			nodes.each do |node|
				children = nodes.select {|n| n['parent'] == node['url'] }
				node['has_children?'] = children.size > 0			
			end	
		end			

	end
end